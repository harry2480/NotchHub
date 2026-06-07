import Foundation
import Observation

/// Drives the Media tab (要件定義.md §18): now-playing display, transport
/// controls, plus volume / seek / artwork (user-requested extensions).
@MainActor
@Observable
final class MediaViewModel {
    private(set) var nowPlaying: NowPlaying?
    /// Artwork for the current track, fetched off the poll path on track change.
    private(set) var artwork: Data?

    /// Slider-bound volume (0–100). Mirrors the player except while the user
    /// drags, so polling never fights the gesture.
    var volume: Double = 50
    /// Slider-bound playback position, in seconds.
    var position: Double = 0

    /// True while the user drags the respective slider.
    private(set) var isAdjustingVolume = false
    private(set) var isScrubbing = false

    var duration: Double {
        nowPlaying?.duration ?? 0
    }

    private let service: MediaService
    @ObservationIgnored private var pollTimer: Timer?
    @ObservationIgnored private var artworkKey: String?

    init(service: MediaService) {
        self.service = service
    }

    func refresh() {
        let track = service.nowPlaying()
        nowPlaying = track
        guard let track else {
            artwork = nil
            artworkKey = nil
            position = 0
            return
        }
        if !isAdjustingVolume { volume = Double(track.volume) }
        if !isScrubbing { position = track.position }
        loadArtworkIfNeeded(for: track)
    }

    /// Fetches artwork only when the track changes (the fetch may hit AppleScript
    /// or the network, so it must not run on every poll tick).
    private func loadArtworkIfNeeded(for track: NowPlaying) {
        guard track.identityKey != artworkKey else { return }
        artworkKey = track.identityKey
        artwork = service.artwork()
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

    // MARK: - Volume

    /// Called by the volume slider: while dragging, suppress poll overwrites; on
    /// release, push the new volume to the player.
    func volumeEditingChanged(_ editing: Bool) {
        isAdjustingVolume = editing
        if !editing { service.setVolume(Int(volume.rounded())) }
    }

    // MARK: - Seek

    /// Called by the position slider: while scrubbing, suppress poll overwrites;
    /// on release, seek the player to the chosen position.
    func seekEditingChanged(_ editing: Bool) {
        isScrubbing = editing
        if !editing {
            service.seek(to: position)
            refresh()
        }
    }
}
