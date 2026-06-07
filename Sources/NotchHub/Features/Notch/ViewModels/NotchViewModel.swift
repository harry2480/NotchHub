import CoreGraphics
import Observation

/// Drives the notch window's mode, minimal status and drag interaction
/// (要件定義.md §5–7). All UI-facing state lives here; the AppKit window and
/// SwiftUI views are thin renderers of it.
///
/// The view model owns the *rules*: it expands only on the permitted triggers,
/// resolves the single highest-priority minimal status, hit-tests drop zones,
/// and runs a drop only when released over an active zone.
@MainActor
@Observable
final class NotchViewModel {
    private(set) var mode: NotchMode = .collapsed
    private(set) var currentScreen: ScreenInfo
    private(set) var dragSession: DragSession?
    private(set) var toast: ToastMessage?

    /// Signals currently active; the collapsed notch shows the highest-priority one.
    private(set) var activeSignals: Set<MinimalStatus> = []

    /// The single status shown while collapsed, or `nil` to stay assimilated.
    var minimalStatus: MinimalStatus? {
        MinimalStatus.resolve(from: activeSignals)
    }

    private let screenProvider: ScreenProviding
    private let dropCoordinator: DropCoordinating
    private var lastDrop: DropRequest?

    init(screenProvider: ScreenProviding, dropCoordinator: DropCoordinating) {
        self.screenProvider = screenProvider
        self.dropCoordinator = dropCoordinator
        currentScreen = screenProvider.main
    }

    // MARK: - Expansion / collapse

    /// Click on the notch toggles the expanded content (要件定義.md §5.2).
    func click() {
        switch mode {
        case .collapsed:
            expand(trigger: .click)
        case .expanded:
            collapse()
        case .dragging:
            break // a click during a drag is ignored
        }
    }

    /// Expands per an allowed trigger. Drag approach shows the drop zones;
    /// click / AI approval show the full content.
    func expand(trigger: NotchTrigger) {
        switch trigger {
        case .dragApproach:
            mode = .dragging
        case .click, .aiApproval:
            mode = .expanded
        }
    }

    /// Closes the notch (notch-outside click or Esc — 要件定義.md §5.3).
    func collapse() {
        mode = .collapsed
        dragSession = nil
        activeSignals.remove(.dragging)
    }

    // MARK: - Minimal status signals

    func setSignal(_ status: MinimalStatus, active: Bool) {
        if active {
            activeSignals.insert(status)
        } else {
            activeSignals.remove(status)
        }
    }

    /// An AI CLI raised an approval request: record it and auto-expand
    /// (要件定義.md §13.3).
    func aiApprovalRequested() {
        activeSignals.insert(.aiApprovalWaiting)
        expand(trigger: .aiApproval)
    }

    // MARK: - Drag interaction

    /// A drag approached the notch. Targets the display under the cursor
    /// (要件定義.md §19.2) and shows the drop zones.
    func dragApproached(at point: CGPoint) {
        if let screen = screenProvider.screen(containing: point) {
            currentScreen = screen
        }
        activeSignals.insert(.dragging)
        mode = .dragging
        dragSession = DragSession(cursor: point, screenID: currentScreen.id, hoveredZone: hoveredZone(at: point))
    }

    /// The drag moved; recompute which zone (if any) is highlighted.
    func dragMoved(to point: CGPoint) {
        guard mode == .dragging else { return }
        if let screen = screenProvider.screen(containing: point), screen.id != currentScreen.id {
            currentScreen = screen
        }
        dragSession = DragSession(cursor: point, screenID: currentScreen.id, hoveredZone: hoveredZone(at: point))
    }

    /// The zone that a drop would currently target (the highlighted one).
    /// The view captures this synchronously at mouse-up — before the async
    /// item-provider load completes and before ``dragCancelled()`` clears the
    /// session — so the drop is not lost to that race.
    var pendingDropZone: DropZone? {
        dragSession?.hoveredZone
    }

    /// Commits a drop to an explicit zone (要件定義.md §7.4 "Drop 時のみ実行").
    /// A no-op when there are no items.
    func commitDrop(items: [DroppedItem], zone: DropZone) {
        defer { collapse() }
        guard !items.isEmpty else { return }
        let request = DropRequest(zone: zone, items: items)
        lastDrop = request
        toast = dropCoordinator.handle(request)
    }

    /// Convenience for the common path: drop onto the currently highlighted
    /// zone. A no-op when over a dead zone.
    func drop(items: [DroppedItem]) {
        guard let zone = pendingDropZone else {
            collapse()
            return
        }
        commitDrop(items: items, zone: zone)
    }

    /// Drag cancelled / released away from the notch without dropping.
    func dragCancelled() {
        collapse()
    }

    /// Undoes the most recent undoable drop (要件定義.md §7.4 Undo).
    func undoLastDrop() {
        guard let request = lastDrop, toast?.isUndoable == true else { return }
        dropCoordinator.undo(request)
        lastDrop = nil
        toast = ToastMessage(text: "Undone")
    }

    func dismissToast() {
        toast = nil
    }

    /// Shows a toast from outside a drop (e.g. a screenshot was auto-imported —
    /// 要件定義.md §9.2).
    func showToast(_ message: ToastMessage) {
        toast = message
    }

    /// The zone currently under the cursor given the dragging notch frame.
    func hoveredZone(at point: CGPoint) -> DropZone? {
        let frame = NotchGeometry.frame(for: .dragging, on: currentScreen)
        return DragZoneLayout(frame: frame).zone(at: point)
    }
}
