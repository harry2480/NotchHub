import CoreGraphics

/// Geometry of a display, used for multi-display notch placement
/// (要件定義.md §19.2). Frames use AppKit's bottom-left origin convention.
struct ScreenInfo: Equatable, Identifiable {
    let id: Int
    /// Full screen frame in global coordinates (bottom-left origin).
    let frame: CGRect
    /// Whether the display has a physical notch.
    let hasNotch: Bool
    /// Physical notch size when `hasNotch` is true.
    let notchSize: CGSize?

    init(id: Int, frame: CGRect, hasNotch: Bool = false, notchSize: CGSize? = nil) {
        self.id = id
        self.frame = frame
        self.hasNotch = hasNotch
        self.notchSize = notchSize
    }

    func contains(_ point: CGPoint) -> Bool {
        frame.contains(point)
    }
}
