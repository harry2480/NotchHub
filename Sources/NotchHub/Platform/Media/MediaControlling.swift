import Foundation

/// Reads and controls Apple Music / Spotify, hiding AppleScript behind a
/// protocol (AGENTS.md). Automation permission is requested on demand.
protocol MediaControlling {
    func nowPlaying() -> NowPlaying?
    func playPause()
    func next()
    func previous()
    /// Launches the default supported player (Apple Music) so the user can start
    /// playback when nothing is playing.
    func openDefaultPlayer()
    /// Sets the active player's output volume (0–100).
    func setVolume(_ value: Int)
    /// Seeks the active player to `seconds` from the track start.
    func seek(to seconds: Double)
    /// Raw artwork bytes for the current track (nil when none / not playing).
    /// May block briefly; call off the main thread or only on track changes.
    func artwork() -> Data?
}
