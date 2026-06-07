import AppKit
import SwiftUI

/// The notch panel's content view: hosts the SwiftUI ``NotchRootView`` and is a
/// system drag destination (実装計画.md §2.2). Making the panel itself the
/// destination means a real file drag (`NSDraggingSession`) reliably triggers
/// `draggingEntered` — unlike a global mouse monitor — and the panel grows to
/// reveal the drop zones while the drag is tracked.
final class DropHostingView: NSView {
    /// Cursor moved within the panel during a drag (global coordinates).
    var onDragMoved: ((CGPoint) -> Void)?
    /// Drag left the panel without dropping.
    var onDragExited: (() -> Void)?
    /// Items were dropped on the panel.
    var onDrop: (([DroppedItem]) -> Void)?

    init(rootView: NotchRootView) {
        super.init(frame: .zero)
        let host = NSHostingView(rootView: rootView)
        host.translatesAutoresizingMaskIntoConstraints = false
        addSubview(host)
        NSLayoutConstraint.activate([
            host.leadingAnchor.constraint(equalTo: leadingAnchor),
            host.trailingAnchor.constraint(equalTo: trailingAnchor),
            host.topAnchor.constraint(equalTo: topAnchor),
            host.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])
        registerForDraggedTypes([.fileURL, .URL, .string])
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        nil
    }

    override func draggingEntered(_ sender: NSDraggingInfo) -> NSDragOperation {
        onDragMoved?(globalPoint(of: sender))
        return .copy
    }

    override func draggingUpdated(_ sender: NSDraggingInfo) -> NSDragOperation {
        onDragMoved?(globalPoint(of: sender))
        return .copy
    }

    override func draggingExited(_: NSDraggingInfo?) {
        onDragExited?()
    }

    override func performDragOperation(_ sender: NSDraggingInfo) -> Bool {
        let items = Self.items(from: sender.draggingPasteboard)
        guard !items.isEmpty else { return false }
        onDrop?(items)
        return true
    }

    private func globalPoint(of sender: NSDraggingInfo) -> CGPoint {
        window?.convertPoint(toScreen: sender.draggingLocation) ?? sender.draggingLocation
    }

    /// Converts a dragging pasteboard into domain ``DroppedItem``s.
    static func items(from pasteboard: NSPasteboard) -> [DroppedItem] {
        let options: [NSPasteboard.ReadingOptionKey: Any] = [.urlReadingFileURLsOnly: false]
        if let urls = pasteboard.readObjects(forClasses: [NSURL.self], options: options) as? [URL], !urls.isEmpty {
            return urls.map { $0.isFileURL ? .fileURL($0) : .url($0) }
        }
        if let strings = pasteboard.readObjects(forClasses: [NSString.self], options: nil) as? [String] {
            return strings.map(DroppedItem.text)
        }
        return []
    }
}
