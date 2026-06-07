@testable import NotchHub
import Testing

@MainActor
struct NotchWindowControllerTests {
    @Test
    func initialFrameDoesNotAnimate() {
        let next = state(.collapsed)

        #expect(!NotchWindowController.shouldAnimateFrameTransition(from: nil, to: next))
    }

    @Test
    func regularExpandAndCollapseAnimateOnSameScreen() {
        #expect(
            NotchWindowController.shouldAnimateFrameTransition(
                from: state(.collapsed),
                to: state(.expanded)
            )
        )
        #expect(
            NotchWindowController.shouldAnimateFrameTransition(
                from: state(.expanded),
                to: state(.collapsed)
            )
        )
    }

    @Test
    func transitionsIntoOrOutOfDraggingDoNotAnimate() {
        #expect(
            !NotchWindowController.shouldAnimateFrameTransition(
                from: state(.collapsed),
                to: state(.dragging)
            )
        )
        #expect(
            !NotchWindowController.shouldAnimateFrameTransition(
                from: state(.dragging),
                to: state(.collapsed)
            )
        )
    }

    @Test
    func displayChangesDoNotAnimate() {
        #expect(
            !NotchWindowController.shouldAnimateFrameTransition(
                from: state(.collapsed, screenID: 0),
                to: state(.expanded, screenID: 1)
            )
        )
    }

    @Test
    func unchangedStateDoesNotAnimate() {
        let state = state(.expanded)

        #expect(!NotchWindowController.shouldAnimateFrameTransition(from: state, to: state))
    }

    private func state(
        _ mode: NotchMode,
        screenID: ScreenInfo.ID = 0
    ) -> NotchWindowController.FrameState {
        NotchWindowController.FrameState(mode: mode, screenID: screenID)
    }
}
