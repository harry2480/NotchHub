import AppKit

/// Production ``MediaControlling`` driving Apple Music / Spotify via AppleScript
/// (要件定義.md §18). Prefers whichever app is currently playing.
///
/// AppleScript is only run when the target app is actually running (checked via
/// `NSWorkspace.runningApplications`, which never prompts). Scripts address the
/// app by bundle id (`tell application id …`) so macOS never shows a "Choose
/// Application" locate dialog — a repeating one of those was the bug behind the
/// undismissable Choose/Cancel prompt.
final class AppleScriptMediaController: MediaControlling {
    private enum Player {
        static let music = "com.apple.Music"
        static let spotify = "com.spotify.client"
    }

    func nowPlaying() -> NowPlaying? {
        let music = read(source: .appleMusic)
        let spotify = read(source: .spotify)
        if let music, music.isPlaying { return music }
        if let spotify, spotify.isPlaying { return spotify }
        return music ?? spotify
    }

    func playPause() {
        run(command: "playpause", on: activeSource())
    }

    func next() {
        run(command: "next track", on: activeSource())
    }

    func previous() {
        run(command: "previous track", on: activeSource())
    }

    func openDefaultPlayer() {
        if let url = NSWorkspace.shared.urlForApplication(withBundleIdentifier: Player.music) {
            NSWorkspace.shared.openApplication(at: url, configuration: NSWorkspace.OpenConfiguration())
        }
    }

    func setVolume(_ value: Int) {
        let clamped = max(0, min(100, value))
        run(command: "set sound volume to \(clamped)", on: activeSource())
    }

    func seek(to seconds: Double) {
        // Both players take seconds for `player position`.
        let position = max(0, seconds)
        run(command: "set player position to \(position)", on: activeSource())
    }

    func artwork() -> Data? {
        let source = activeSource()
        guard isRunning(source) else { return nil }
        switch source {
        case .appleMusic:
            // Apple Music exposes raw artwork bytes locally (no network).
            let script = """
            tell application id "\(Player.music)"
                if player state is not stopped and (count of artworks of current track) > 0 then
                    return data of artwork 1 of current track
                end if
            end tell
            """
            return runScriptData(script)
        case .spotify:
            // Spotify only exposes an artwork URL; fetch it (track-change only).
            let script = "tell application id \"\(Player.spotify)\" to get artwork url of current track"
            guard let urlString = runScript(script), let url = URL(string: urlString) else { return nil }
            return try? Data(contentsOf: url)
        }
    }

    // MARK: - AppleScript

    private func bundleID(_ source: NowPlaying.Source) -> String {
        source == .spotify ? Player.spotify : Player.music
    }

    /// Whether the player is running — checked without AppleScript so no dialog
    /// or Automation prompt is triggered when it isn't.
    private func isRunning(_ source: NowPlaying.Source) -> Bool {
        let id = bundleID(source)
        return NSWorkspace.shared.runningApplications.contains { $0.bundleIdentifier == id }
    }

    private func read(source: NowPlaying.Source) -> NowPlaying? {
        guard isRunning(source) else { return nil }
        let script = """
        tell application id "\(bundleID(source))"
            if player state is playing or player state is paused then
                set t to current track
                return (name of t) & "\\n" & (artist of t) & "\\n" & (player state is playing) ¬
                    & "\\n" & (player position) & "\\n" & (duration of t) & "\\n" & (sound volume)
            end if
        end tell
        return ""
        """
        guard let output = runScript(script), !output.isEmpty else { return nil }
        let parts = output.components(separatedBy: "\n")
        guard parts.count >= 6 else { return nil }
        // Spotify reports track duration in milliseconds; Apple Music in seconds.
        let rawDuration = Double(parts[4]) ?? 0
        let duration = source == .spotify ? rawDuration / 1000 : rawDuration
        return NowPlaying(
            source: source,
            title: parts[0],
            artist: parts[1],
            isPlaying: parts[2].contains("true"),
            position: Double(parts[3]) ?? 0,
            duration: duration,
            volume: Int(Double(parts[5]) ?? 0),
            artwork: nil
        )
    }

    private func run(command: String, on source: NowPlaying.Source) {
        guard isRunning(source) else { return }
        _ = runScript("tell application id \"\(bundleID(source))\" to \(command)")
    }

    private func activeSource() -> NowPlaying.Source {
        nowPlaying()?.source ?? .appleMusic
    }

    @discardableResult
    private func runScript(_ source: String) -> String? {
        var error: NSDictionary?
        guard let script = NSAppleScript(source: source) else { return nil }
        let result = script.executeAndReturnError(&error)
        if let error {
            Log.app.error("AppleScript error: \(error.description, privacy: .public)")
            return nil
        }
        return result.stringValue
    }

    /// Runs a script whose result is raw bytes (e.g. artwork data).
    private func runScriptData(_ source: String) -> Data? {
        var error: NSDictionary?
        guard let script = NSAppleScript(source: source) else { return nil }
        let result = script.executeAndReturnError(&error)
        if let error {
            Log.app.error("AppleScript error: \(error.description, privacy: .public)")
            return nil
        }
        let data = result.data
        return data.isEmpty ? nil : data
    }
}
