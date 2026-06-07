import CoreGraphics
import Foundation
@testable import NotchHub
import Testing

@MainActor
struct NotchViewModelTests {
    private let screen = ScreenInfo(id: 0, frame: CGRect(x: 0, y: 0, width: 1440, height: 900))

    private func makeViewModel(
        screens: [ScreenInfo]? = nil
    ) -> (NotchViewModel, StubDropCoordinator) {
        let provider = StubScreenProvider(screens: screens ?? [screen])
        let coordinator = StubDropCoordinator()
        return (NotchViewModel(screenProvider: provider, dropCoordinator: coordinator), coordinator)
    }

    /// A global point at the centre of a zone's active rect on `screen`.
    private func point(in zone: DropZone) -> CGPoint {
        let frame = NotchGeometry.frame(for: .dragging, on: screen)
        let rect = DragZoneLayout(frame: frame).rect(for: zone)
        return CGPoint(x: rect.midX, y: rect.midY)
    }

    // MARK: - Expansion

    @Test
    func clickTogglesExpansion() {
        let (viewModel, _) = makeViewModel()
        #expect(viewModel.mode == .collapsed)
        viewModel.click()
        #expect(viewModel.mode == .expanded)
        viewModel.click()
        #expect(viewModel.mode == .collapsed)
    }

    @Test
    func dragApproachExpandsToDragging() {
        let (viewModel, _) = makeViewModel()
        viewModel.expand(trigger: .dragApproach)
        #expect(viewModel.mode == .dragging)
    }

    @Test
    func aiApprovalAddsSignalAndAutoExpands() {
        let (viewModel, _) = makeViewModel()
        viewModel.aiApprovalRequested()
        #expect(viewModel.mode == .expanded)
        #expect(viewModel.minimalStatus == .aiApprovalWaiting)
    }

    // MARK: - Minimal status

    @Test
    func minimalStatusReflectsHighestPrioritySignal() {
        let (viewModel, _) = makeViewModel()
        viewModel.setSignal(.mediaPlaying, active: true)
        viewModel.setSignal(.upcomingEvent, active: true)
        #expect(viewModel.minimalStatus == .mediaPlaying)
        viewModel.setSignal(.mediaPlaying, active: false)
        #expect(viewModel.minimalStatus == .upcomingEvent)
    }

    // MARK: - Drag → drop

    @Test
    func dropOnZoneInvokesCoordinatorAndShowsToast() {
        let (viewModel, coordinator) = makeViewModel()
        viewModel.dragApproached(at: point(in: .shelf))
        #expect(viewModel.mode == .dragging)
        #expect(viewModel.dragSession?.hoveredZone == .shelf)

        viewModel.drop(items: [.text("hello")])

        #expect(coordinator.handled.count == 1)
        #expect(coordinator.handled.first?.zone == .shelf)
        #expect(viewModel.toast?.isUndoable == true)
        #expect(viewModel.mode == .collapsed) // collapses after a drop
    }

    @Test
    func dropOnDeadZoneIsNoOp() {
        let (viewModel, coordinator) = makeViewModel()
        // A point between two columns is a dead zone.
        let frame = NotchGeometry.frame(for: .dragging, on: screen)
        let between = CGPoint(
            x: DragZoneLayout(frame: frame).rect(for: .shelf).maxX + 2,
            y: frame.midY
        )
        viewModel.dragApproached(at: between)
        #expect(viewModel.dragSession?.hoveredZone == nil)

        viewModel.drop(items: [.text("hello")])

        #expect(coordinator.handled.isEmpty)
        #expect(viewModel.toast == nil)
        #expect(viewModel.mode == .collapsed)
    }

    @Test
    func emptyDropDoesNothing() {
        let (viewModel, coordinator) = makeViewModel()
        viewModel.dragApproached(at: point(in: .airDrop))
        viewModel.drop(items: [])
        #expect(coordinator.handled.isEmpty)
        #expect(viewModel.mode == .collapsed)
    }

    // MARK: - Undo

    @Test
    func undoReversesUndoableDrop() {
        let (viewModel, coordinator) = makeViewModel()
        viewModel.dragApproached(at: point(in: .shelf))
        viewModel.drop(items: [.text("hello")])

        viewModel.undoLastDrop()

        #expect(coordinator.undone.count == 1)
        #expect(viewModel.toast?.text == "Undone")
    }

    @Test
    func undoIgnoredForNonUndoableDrop() {
        let (viewModel, coordinator) = makeViewModel()
        viewModel.dragApproached(at: point(in: .airDrop)) // AirDrop toast is not undoable
        viewModel.drop(items: [.fileURL(URL(fileURLWithPath: "/tmp/x"))])

        viewModel.undoLastDrop()

        #expect(coordinator.undone.isEmpty)
    }

    // MARK: - Multi-display

    @Test
    func dragTargetsDisplayUnderCursor() {
        let primary = ScreenInfo(id: 0, frame: CGRect(x: 0, y: 0, width: 1440, height: 900))
        let external = ScreenInfo(id: 1, frame: CGRect(x: 1440, y: 0, width: 1920, height: 1080))
        let (viewModel, _) = makeViewModel(screens: [primary, external])

        viewModel.dragApproached(at: CGPoint(x: 1440 + 960, y: 1075)) // top-centre of external
        #expect(viewModel.currentScreen.id == external.id)
    }
}
