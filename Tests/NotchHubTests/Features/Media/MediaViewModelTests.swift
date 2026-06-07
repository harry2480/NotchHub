import Foundation
@testable import NotchHub
import Testing

@MainActor
struct MediaViewModelTests {
    private func track(
        playing: Bool,
        title: String = "Song",
        position: Double = 0,
        duration: Double = 0,
        volume: Int = 0
    ) -> NowPlaying {
        NowPlaying(
            source: .appleMusic,
            title: title,
            artist: "Artist",
            isPlaying: playing,
            position: position,
            duration: duration,
            volume: volume
        )
    }

    @Test
    func refreshReadsNowPlaying() {
        let controller = StubMediaController(current: track(playing: true))
        let viewModel = MediaViewModel(service: MediaService(controller: controller))
        viewModel.refresh()
        #expect(viewModel.nowPlaying?.title == "Song")
    }

    @Test
    func transportControlsDelegateToController() {
        let controller = StubMediaController(current: track(playing: true))
        let viewModel = MediaViewModel(service: MediaService(controller: controller))
        viewModel.playPause()
        viewModel.next()
        viewModel.previous()
        #expect(controller.commands == ["playPause", "next", "previous"])
    }

    @Test
    func refreshMirrorsVolumeAndPosition() {
        let controller = StubMediaController(current: track(playing: true, position: 42, duration: 180, volume: 70))
        let viewModel = MediaViewModel(service: MediaService(controller: controller))
        viewModel.refresh()
        #expect(viewModel.volume == 70)
        #expect(viewModel.position == 42)
        #expect(viewModel.duration == 180)
    }

    @Test
    func volumeIsNotOverwrittenWhileAdjusting() {
        let controller = StubMediaController(current: track(playing: true, volume: 70))
        let viewModel = MediaViewModel(service: MediaService(controller: controller))
        viewModel.volume = 10
        viewModel.volumeEditingChanged(true) // begin drag
        viewModel.refresh() // poll must not clobber the in-flight gesture
        #expect(viewModel.volume == 10)
    }

    @Test
    func releasingVolumeSliderPushesToController() {
        let controller = StubMediaController(current: track(playing: true, volume: 70))
        let viewModel = MediaViewModel(service: MediaService(controller: controller))
        viewModel.volume = 25
        viewModel.volumeEditingChanged(true)
        viewModel.volumeEditingChanged(false) // release
        #expect(controller.lastVolume == 25)
    }

    @Test
    func releasingSeekSliderSeeksController() {
        let controller = StubMediaController(current: track(playing: true, position: 0, duration: 200))
        let viewModel = MediaViewModel(service: MediaService(controller: controller))
        viewModel.position = 120
        viewModel.seekEditingChanged(true)
        viewModel.seekEditingChanged(false)
        #expect(controller.lastSeek == 120)
    }

    @Test
    func positionIsNotOverwrittenWhileScrubbing() {
        let controller = StubMediaController(current: track(playing: true, position: 5, duration: 200))
        let viewModel = MediaViewModel(service: MediaService(controller: controller))
        viewModel.position = 150
        viewModel.seekEditingChanged(true)
        viewModel.refresh()
        #expect(viewModel.position == 150)
    }

    @Test
    func localArtworkLoadsSynchronously() {
        let controller = StubMediaController(
            current: track(playing: true, title: "First"),
            artwork: .data(Data([0x1, 0x2, 0x3]))
        )
        let viewModel = MediaViewModel(service: MediaService(controller: controller))
        viewModel.refresh()
        #expect(viewModel.artwork == Data([0x1, 0x2, 0x3]))
    }

    @Test
    func remoteArtworkLoadsAsynchronouslyWithoutBlocking() async throws {
        // Use a file:// URL so the test is deterministic and offline-safe.
        let tmp = URL(fileURLWithPath: NSTemporaryDirectory())
            .appendingPathComponent("notchhub-art-\(UUID().uuidString).bin")
        let bytes = Data([0xA, 0xB, 0xC, 0xD])
        try bytes.write(to: tmp)
        defer { try? FileManager.default.removeItem(at: tmp) }

        let controller = StubMediaController(current: track(playing: true), artwork: .remote(tmp))
        let viewModel = MediaViewModel(service: MediaService(controller: controller))
        viewModel.refresh()
        #expect(viewModel.artwork == nil) // not blocking: not yet loaded

        try await waitUntil { viewModel.artwork == bytes }
        #expect(viewModel.artwork == bytes)
    }

    @Test
    func failedLocalArtworkIsNotCached() {
        // nil artwork (e.g. track has none) must not be cached as success, so a
        // later poll that does have artwork still loads it.
        let controller = StubMediaController(current: track(playing: true), artwork: nil)
        let viewModel = MediaViewModel(service: MediaService(controller: controller))
        viewModel.refresh()
        #expect(viewModel.artwork == nil)

        controller.stubbedArtwork = .data(Data([0x9]))
        viewModel.refresh() // same track, but artwork now available
        #expect(viewModel.artwork == Data([0x9]))
    }

    /// Polls a main-actor condition until it holds or a short timeout elapses.
    private func waitUntil(_ condition: () -> Bool, attempts: Int = 50) async throws {
        for _ in 0 ..< attempts {
            if condition() { return }
            try await Task.sleep(nanoseconds: 10_000_000)
        }
    }

    @Test
    func timeStringFormatsMinutesAndSeconds() {
        #expect(MediaControlView.timeString(0) == "0:00")
        #expect(MediaControlView.timeString(65) == "1:05")
        #expect(MediaControlView.timeString(-3) == "0:00")
    }
}
