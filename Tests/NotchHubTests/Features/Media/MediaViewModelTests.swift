@testable import NotchHub
import Testing

@MainActor
struct MediaViewModelTests {
    private func track(playing: Bool) -> NowPlaying {
        NowPlaying(source: .appleMusic, title: "Song", artist: "Artist", isPlaying: playing, artwork: nil)
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
}
