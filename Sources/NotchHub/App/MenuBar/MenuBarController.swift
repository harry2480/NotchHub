import AppKit

/// Owns the menu-bar status item and its menu (要件定義.md §12.1):
/// Settings / Launch at Login / Quit. Lives on the main thread (installed from
/// `applicationDidFinishLaunching`).
final class MenuBarController {
    private let statusItem: NSStatusItem
    private let loginItemManager: LoginItemManaging
    private let onOpenSettings: () -> Void

    init(loginItemManager: LoginItemManaging, onOpenSettings: @escaping () -> Void) {
        self.loginItemManager = loginItemManager
        self.onOpenSettings = onOpenSettings
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        configure()
    }

    private func configure() {
        if let button = statusItem.button {
            button.image = NSImage(
                systemSymbolName: "rectangle.tophalf.inset.filled",
                accessibilityDescription: "NotchHub"
            )
            button.image?.isTemplate = true
        }
        rebuildMenu()
    }

    private func rebuildMenu() {
        let menu = NSMenu()

        let settingsItem = NSMenuItem(title: "Settings…", action: #selector(openSettings), keyEquivalent: ",")
        settingsItem.target = self
        menu.addItem(settingsItem)

        let launchItem = NSMenuItem(
            title: "Launch at Login",
            action: #selector(toggleLaunchAtLogin),
            keyEquivalent: ""
        )
        launchItem.target = self
        launchItem.state = loginItemManager.isEnabled ? .on : .off
        menu.addItem(launchItem)

        menu.addItem(.separator())

        let quitItem = NSMenuItem(title: "Quit NotchHub", action: #selector(quit), keyEquivalent: "q")
        quitItem.target = self
        menu.addItem(quitItem)

        statusItem.menu = menu
    }

    @objc
    private func openSettings() {
        onOpenSettings()
    }

    @objc
    private func toggleLaunchAtLogin() {
        do {
            if loginItemManager.isEnabled {
                try loginItemManager.disable()
            } else {
                try loginItemManager.enable()
            }
        } catch {
            Log.app.error("Toggling Launch at Login failed: \(error.localizedDescription, privacy: .public)")
        }
        rebuildMenu()
    }

    @objc
    private func quit() {
        NSApplication.shared.terminate(nil)
    }
}
