import Observation

/// Drives the Media tab (要件定義.md §18): now-playing display and basic
/// transport controls. Search / volume / playlists are out of scope (§18.3).
@MainActor
@Observable
final class MediaViewModel {
    private(set) var nowPlaying: NowPlaying?

    private let controller: MediaControlling

    init(controller: MediaControlling) {
        self.controller = controller
    }

    func refresh() {
        nowPlaying = controller.nowPlaying()
    }

    func playPause() {
        controller.playPause()
        refresh()
    }

    func next() {
        controller.next()
        refresh()
    }

    func previous() {
        controller.previous()
        refresh()
    }
}
