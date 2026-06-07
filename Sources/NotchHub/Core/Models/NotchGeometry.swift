import CoreGraphics

/// Computes the notch window frame, centred at the top of a screen
/// (実装計画.md §2.2). Pure geometry so it can be unit-tested without AppKit.
enum NotchGeometry {
    /// The notch window frame for `mode` on `screen`, in global coordinates
    /// (bottom-left origin). The window hugs the top edge, horizontally centred.
    static func frame(for mode: NotchMode, on screen: ScreenInfo) -> CGRect {
        let size = NotchLayout.size(for: mode)
        let originX = screen.frame.midX - size.width / 2
        let originY = screen.frame.maxY - size.height
        return CGRect(x: originX, y: originY, width: size.width, height: size.height)
    }

    /// Whether `point` (global, bottom-left origin) is approaching the notch on
    /// `screen` — i.e. within the dragging-zone width horizontally and within
    /// `verticalThreshold` of the top edge. This is the drag-expansion trigger
    /// (要件定義.md §5.2); proximity elsewhere must not expand.
    static func isApproaching(
        _ point: CGPoint,
        on screen: ScreenInfo,
        verticalThreshold: CGFloat = 12
    ) -> Bool {
        let triggerWidth = NotchLayout.dragging.width
        let minX = screen.frame.midX - triggerWidth / 2
        let maxX = screen.frame.midX + triggerWidth / 2
        let topY = screen.frame.maxY
        let withinX = point.x >= minX && point.x <= maxX
        let withinTop = point.y <= topY && (topY - point.y) <= verticalThreshold
        return withinX && withinTop
    }
}
