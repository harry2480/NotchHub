import CoreGraphics

/// Observes system-wide left-mouse drags so the notch can expand when a drag
/// approaches the top-centre of the screen (実装計画.md §2.2). Hides
/// `NSEvent` global monitors behind a protocol for testability.
protocol GlobalDragMonitoring: AnyObject {
    /// Called with the global cursor position on each drag movement.
    var onDragMoved: ((CGPoint) -> Void)? { get set }
    /// Called when the drag (left mouse button) is released.
    var onDragEnded: (() -> Void)? { get set }

    func start()
    func stop()
}
