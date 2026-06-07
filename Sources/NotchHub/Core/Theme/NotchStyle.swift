import SwiftUI

/// Shared visual constants for the notch UI so views avoid magic numbers and
/// direct colours (スタイルガイド.md §2). Colours are semantic except the notch
/// fill, which is intentionally black to blend with the physical hardware notch.
enum NotchStyle {
    static let cornerRadius: CGFloat = 16
    static let contentPadding: CGFloat = 12
    static let zoneSpacing: CGFloat = 8
    static let zoneCornerRadius: CGFloat = 12

    /// The notch body colour — black to assimilate with the hardware notch.
    static let notchFill = Color.black
}
