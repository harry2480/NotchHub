import Foundation

/// Media playback business logic over the ``MediaControlling`` platform
/// (要件定義.md §18). Keeps the ViewModel depending on a Service rather than the
/// OS-facing protocol (アーキテクチャ.md 依存方向).
final class MediaService {
    private let controller: MediaControlling

    init(controller: MediaControlling) {
        self.controller = controller
    }

    func nowPlaying() -> NowPlaying? {
        controller.nowPlaying()
    }

    func playPause() {
        controller.playPause()
    }

    func next() {
        controller.next()
    }

    func previous() {
        controller.previous()
    }

    func openDefaultPlayer() {
        controller.openDefaultPlayer()
    }

    func setVolume(_ value: Int) {
        controller.setVolume(value)
    }

    func seek(to seconds: Double) {
        controller.seek(to: seconds)
    }

    func artwork() -> MediaArtwork? {
        controller.artwork()
    }
}
