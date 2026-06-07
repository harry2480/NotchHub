import AppKit

/// Program entry point. NotchHub is a menu-bar / notch agent, so it runs with
/// `.accessory` activation policy (no Dock icon, see 要件定義.md §5) and drives
/// its own AppKit run loop rather than the SwiftUI `App` lifecycle, which gives
/// the fine-grained `NSPanel` control the notch window needs (Phase 1).
@main
enum NotchHubApp {
    static func main() {
        let application = NSApplication.shared
        let delegate = AppDelegate()
        application.delegate = delegate
        application.setActivationPolicy(.accessory)
        application.run()
    }
}

/// Application lifecycle owner. Builds the Composition Root and installs the
/// menu-bar controller once AppKit has finished launching.
final class AppDelegate: NSObject, NSApplicationDelegate {
    private var composition: AppComposition?
    private var menuBarController: MenuBarController?
    private var notchController: NotchWindowController?
    private var settingsWindowController: SettingsWindowController?

    func applicationDidFinishLaunching(_: Notification) {
        let composition = AppComposition()
        do {
            try composition.bootstrap()
        } catch {
            Log.app.error("Bootstrap failed: \(error.localizedDescription, privacy: .public)")
        }

        let notchController = composition.makeNotchController()
        notchController.start()
        self.notchController = notchController

        let settingsWindowController = composition.makeSettingsWindowController()
        self.settingsWindowController = settingsWindowController

        menuBarController = MenuBarController(
            loginItemManager: composition.loginItemManager,
            onOpenSettings: { [weak settingsWindowController] in settingsWindowController?.show() }
        )

        self.composition = composition
    }

    func applicationWillTerminate(_: Notification) {
        notchController?.stop()
    }
}
