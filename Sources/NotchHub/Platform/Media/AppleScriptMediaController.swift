import Foundation

/// Production ``MediaControlling`` driving Apple Music / Spotify via AppleScript
/// (要件定義.md §18). Prefers whichever app is currently playing.
final class AppleScriptMediaController: MediaControlling {
    func nowPlaying() -> NowPlaying? {
        // Read each source once to avoid redundant AppleScript IPC.
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

    // MARK: - AppleScript

    private func activeSource() -> NowPlaying.Source {
        nowPlaying()?.source ?? .appleMusic
    }

    private func appName(_ source: NowPlaying.Source) -> String {
        source == .spotify ? "Spotify" : "Music"
    }

    private func read(source: NowPlaying.Source) -> NowPlaying? {
        let app = appName(source)
        let script = """
        if application "\(app)" is running then
            tell application "\(app)"
                if player state is playing or player state is paused then
                    set trackName to name of current track
                    set artistName to artist of current track
                    set playing to (player state is playing)
                    return trackName & "\\n" & artistName & "\\n" & playing
                end if
            end tell
        end if
        return ""
        """
        guard let output = runScript(script), !output.isEmpty else { return nil }
        let parts = output.components(separatedBy: "\n")
        guard parts.count >= 3 else { return nil }
        return NowPlaying(
            source: source,
            title: parts[0],
            artist: parts[1],
            isPlaying: parts[2].contains("true"),
            artwork: nil
        )
    }

    private func run(command: String, on source: NowPlaying.Source) {
        _ = runScript("tell application \"\(appName(source))\" to \(command)")
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
}
