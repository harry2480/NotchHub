import CoreGraphics

/// Computes the notch window frame, centred at the top of a screen
/// (実装計画.md §2.2). Pure geometry so it can be unit-tested without AppKit.
enum NotchGeometry {
    /// The window size for `mode` on `screen`. On a notch display the collapsed
    /// state hugs the *real* notch (要件定義.md §3.2: ノッチありの Mac); the
    /// pseudo-notch sizes (要件定義.md §19) are used only on notch-less displays.
    /// Dragging / expanded use the content-panel sizes that drop down below the
    /// notch.
    static func size(for mode: NotchMode, on screen: ScreenInfo) -> CGSize {
        switch mode {
        case .collapsed:
            if screen.hasNotch, let notchSize = screen.notchSize {
                // Extend below the cutout so there's a clickable strip to expand.
                return CGSize(width: notchSize.width, height: notchSize.height + NotchLayout.notchClickMargin)
            }
            return NotchLayout.collapsed
        case .dragging:
            return NotchLayout.dragging
        case .expanded:
            return NotchLayout.expanded
        }
    }

    /// The notch window frame for `mode` on `screen`, in global coordinates
    /// (bottom-left origin), horizontally centred. Collapsed hugs the top edge
    /// (assimilating with the notch); the expanded / dragging panels drop down
    /// *below* the physical notch so their content isn't hidden by the cutout.
    static func frame(for mode: NotchMode, on screen: ScreenInfo) -> CGRect {
        let size = size(for: mode, on: screen)
        let originX = screen.frame.midX - size.width / 2
        let topInset = (mode == .collapsed) ? 0 : notchTopInset(of: screen)
        let originY = screen.frame.maxY - topInset - size.height
        return CGRect(x: originX, y: originY, width: size.width, height: size.height)
    }

    /// Height occupied by the physical notch (0 on notch-less displays).
    private static func notchTopInset(of screen: ScreenInfo) -> CGFloat {
        screen.hasNotch ? (screen.notchSize?.height ?? 0) : 0
    }

    /// Whether `point` (global, bottom-left origin) is approaching the notch on
    /// `screen` — i.e. within the dragging-zone width horizontally and within
    /// `verticalThreshold` of the top edge. This is the drag-expansion trigger
    /// (要件定義.md §5.2); proximity elsewhere must not expand.
    static func isApproaching(
        _ point: CGPoint,
        on screen: ScreenInfo,
        verticalThreshold: CGFloat = NotchLayout.dragApproachThreshold
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
