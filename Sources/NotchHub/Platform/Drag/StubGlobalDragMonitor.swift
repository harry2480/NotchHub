import CoreGraphics

/// Test/preview ``GlobalDragMonitoring`` that lets callers drive drag events
/// manually and records start/stop.
final class StubGlobalDragMonitor: GlobalDragMonitoring {
    var onDragMoved: ((CGPoint) -> Void)?
    var onDragEnded: (() -> Void)?

    private(set) var isRunning = false

    func start() {
        isRunning = true
    }

    func stop() {
        isRunning = false
    }

    /// Simulates a drag movement to `point`.
    func emitDragMoved(to point: CGPoint) {
        onDragMoved?(point)
    }

    /// Simulates the drag being released.
    func emitDragEnded() {
        onDragEnded?()
    }
}
