import AppKit

/// The notch `NSPanel`. A borderless panel cannot become key by default, which
/// blocks button clicks and prevents Share Sheet / AirDrop pop-overs from
/// presenting while the notch is open. Allowing it to become key (only when the
/// controller explicitly makes it key, i.e. when expanded) fixes that while
/// keeping it non-activating when idle / dragging.
final class NotchPanel: NSPanel {
    override var canBecomeKey: Bool {
        true
    }

    override var canBecomeMain: Bool {
        false
    }
}
