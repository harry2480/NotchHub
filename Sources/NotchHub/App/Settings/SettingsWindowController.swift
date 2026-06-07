import AppKit
import SwiftUI

/// Hosts ``SettingsView`` in a standard window, opened from the menu bar
/// (要件定義.md §12.1 ⚙ → Settings).
@MainActor
final class SettingsWindowController {
    private let store: SettingsStore
    private var window: NSWindow?

    init(store: SettingsStore) {
        self.store = store
    }

    func show() {
        if window == nil {
            let window = NSWindow(
                contentRect: NSRect(x: 0, y: 0, width: 380, height: 420),
                styleMask: [.titled, .closable],
                backing: .buffered,
                defer: false
            )
            window.title = "NotchHub Settings"
            window.isReleasedWhenClosed = false
            window.contentView = NSHostingView(rootView: SettingsView(store: store))
            window.center()
            self.window = window
        }
        window?.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }
}
