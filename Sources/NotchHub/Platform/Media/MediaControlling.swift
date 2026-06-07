import Foundation

/// Where the current track's artwork comes from. Apple Music exposes raw bytes
/// locally; Spotify only exposes a remote URL that must be fetched off-thread.
enum MediaArtwork: Equatable {
    case data(Data)
    case remote(URL)
}

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
    /// Artwork for the current track: either local bytes or a remote URL to
    /// fetch. Returns nil when there is no artwork / nothing is playing. Only
    /// runs (local) AppleScript — any network fetch is the caller's job, off the
    /// main thread.
    func artwork() -> MediaArtwork?
}
