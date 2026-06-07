import AppKit

/// Production ``GlobalDragMonitoring`` using `NSEvent` global monitors.
///
/// Global monitors observe events delivered to *other* applications, which is
/// exactly what's needed to notice a drag begun in Finder approaching the notch.
/// They require Accessibility permission, requested when monitoring starts
/// (要件定義.md §21: 必要時に要求).
final class AppKitGlobalDragMonitor: GlobalDragMonitoring {
    var onDragMoved: ((CGPoint) -> Void)?
    var onDragEnded: (() -> Void)?

    private var dragMonitor: Any?
    private var upMonitor: Any?

    func start() {
        guard dragMonitor == nil else { return }
        dragMonitor = NSEvent.addGlobalMonitorForEvents(matching: [.leftMouseDragged]) { [weak self] _ in
            self?.onDragMoved?(NSEvent.mouseLocation)
        }
        upMonitor = NSEvent.addGlobalMonitorForEvents(matching: [.leftMouseUp]) { [weak self] _ in
            self?.onDragEnded?()
        }
    }

    func stop() {
        if let dragMonitor {
            NSEvent.removeMonitor(dragMonitor)
        }
        if let upMonitor {
            NSEvent.removeMonitor(upMonitor)
        }
        dragMonitor = nil
        upMonitor = nil
    }

    deinit {
        stop()
    }
}
