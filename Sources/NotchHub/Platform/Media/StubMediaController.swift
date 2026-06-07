import Foundation

/// Test/preview ``MediaControlling`` that records commands and returns a
/// configurable now-playing value.
final class StubMediaController: MediaControlling {
    var current: NowPlaying?
    var stubbedArtwork: MediaArtwork?
    private(set) var commands: [String] = []
    private(set) var lastVolume: Int?
    private(set) var lastSeek: Double?

    init(current: NowPlaying? = nil, artwork: MediaArtwork? = nil) {
        self.current = current
        stubbedArtwork = artwork
    }

    func nowPlaying() -> NowPlaying? {
        current
    }

    func playPause() {
        commands.append("playPause")
    }

    func next() {
        commands.append("next")
    }

    func previous() {
        commands.append("previous")
    }

    func openDefaultPlayer() {
        commands.append("openDefaultPlayer")
    }

    func setVolume(_ value: Int) {
        lastVolume = value
        commands.append("setVolume(\(value))")
    }

    func seek(to seconds: Double) {
        lastSeek = seconds
        commands.append("seek(\(seconds))")
    }

    func artwork() -> MediaArtwork? {
        stubbedArtwork
    }
}
