import Foundation
import Observation

/// Drives the Media tab (要件定義.md §18): now-playing display and basic
/// transport controls. Search / volume / playlists are out of scope (§18.3).
@MainActor
@Observable
final class MediaViewModel {
    private(set) var nowPlaying: NowPlaying?

    private let service: MediaService
    @ObservationIgnored private var pollTimer: Timer?

    init(service: MediaService) {
        self.service = service
    }

    func refresh() {
        nowPlaying = service.nowPlaying()
    }

    /// Refreshes immediately and then polls, so the tab reflects playback that
    /// starts (or stops) while it is open.
    func startPolling(interval: TimeInterval = 2) {
        refresh()
        pollTimer?.invalidate()
        pollTimer = Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { [weak self] _ in
            Task { @MainActor in self?.refresh() }
        }
    }

    func stopPolling() {
        pollTimer?.invalidate()
        pollTimer = nil
    }

    deinit {
        // Guard against a leaked run-loop timer if onDisappear was missed.
        pollTimer?.invalidate()
    }

    /// Opens Apple Music so the user can start playback (要件定義.md §18).
    func openDefaultPlayer() {
        service.openDefaultPlayer()
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
