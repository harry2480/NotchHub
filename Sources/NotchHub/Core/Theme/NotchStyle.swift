import SwiftUI

/// Shared visual constants for the notch UI so views avoid magic numbers and
/// direct colours (スタイルガイド.md §2). Colours are semantic except the notch
/// fill, which is intentionally black to blend with the physical hardware notch.
enum NotchStyle {
    static let cornerRadius: CGFloat = 16
    static let contentPadding: CGFloat = 12
    static let zoneSpacing: CGFloat = 8
    static let zoneCornerRadius: CGFloat = 12

    /// Opacity of the notch body while showing the drop zones.
    static let draggingFillOpacity: CGFloat = 0.92
    /// Duration (seconds) of the expand/collapse transition. Shared by the
    /// SwiftUI content and the `NSPanel` frame so they animate in lockstep.
    static let modeTransitionDuration: Double = 0.26

    /// The expand/collapse animation for the SwiftUI content. Ease-in-out matches
    /// the window's `CAMediaTimingFunction(.easeInEaseOut)` so the content and the
    /// panel resize together instead of drifting apart (which looks like clipping).
    static var modeTransition: Animation {
        .easeInOut(duration: modeTransitionDuration)
    }

    /// Highlight/scale feedback on drop zones — a quick, lightly springy pop.
    static var zoneHighlight: Animation {
        .spring(response: 0.22, dampingFraction: 0.7)
    }

    /// The notch body colour — black to assimilate with the hardware notch.
    static let notchFill = Color.black
}
