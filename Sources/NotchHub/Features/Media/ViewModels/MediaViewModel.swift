import Observation

/// Drives the Media tab (要件定義.md §18): now-playing display and basic
/// transport controls. Search / volume / playlists are out of scope (§18.3).
@MainActor
@Observable
final class MediaViewModel {
    private(set) var nowPlaying: NowPlaying?

    private let service: MediaService

    init(service: MediaService) {
        self.service = service
    }

    func refresh() {
        nowPlaying = service.nowPlaying()
    }

    func playPause() {
        service.playPause()
        refresh()
    }

    func next() {
        service.next()
        refresh()
    }

    func previous() {
        service.previous()
        refresh()
    }
}
