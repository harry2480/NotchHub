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
}
