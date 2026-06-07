import Foundation

/// Test/preview ``MediaControlling`` that records commands and returns a
/// configurable now-playing value.
final class StubMediaController: MediaControlling {
    var current: NowPlaying?
    private(set) var commands: [String] = []

    init(current: NowPlaying? = nil) {
        self.current = current
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
}
