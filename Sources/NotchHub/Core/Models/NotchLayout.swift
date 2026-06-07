import CoreGraphics

/// Notch / pseudo-notch sizes per mode (スタイルガイド.md §3). Sizes are
/// constants so views never hard-code magic numbers.
enum NotchLayout {
    static let collapsed = CGSize(width: 180, height: 32)
    static let dragging = CGSize(width: 520, height: 120)
    static let expanded = CGSize(width: 560, height: 360)

    /// How close (points) to the top edge a drag must come to expand the notch.
    static let dragApproachThreshold: CGFloat = 12
    /// Fraction of each drop column treated as inactive margin (Dead Zone).
    static let dropZoneDeadZoneRatio: CGFloat = 0.16

    static func size(for mode: NotchMode) -> CGSize {
        switch mode {
        case .collapsed: collapsed
        case .dragging: dragging
        case .expanded: expanded
        }
    }
}
