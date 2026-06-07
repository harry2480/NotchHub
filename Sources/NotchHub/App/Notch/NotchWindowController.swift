import AppKit
import QuartzCore
import SwiftUI

/// Owns the notch `NSPanel` and keeps it in sync with the ``NotchViewModel``
/// (実装計画.md §2.1). The panel is borderless, non-activating, floats at
/// status-bar level and joins all Spaces so it always overlays the notch.
///
/// AppKit specifics (panel, global event monitors) live here, isolated from the
/// SwiftUI feature views (フロントエンド規約.md §SwiftUI/AppKit の使い分け).
@MainActor
final class NotchWindowController {
    private let scene: NotchScene
    private let screenshotMonitor: ScreenshotMonitoring
    private let screenshotImporter: ScreenshotImportService
    private let panel: NSPanel
    private let dropHost: DropHostingView

    private var viewModel: NotchViewModel {
        scene.notch
    }

    private var outsideClickMonitor: Any?
    private var keyMonitor: Any?
    /// The first frame application (initial show) must not animate; only later
    /// mode/screen changes animate.
    private var didApplyInitialFrame = false

    init(
        scene: NotchScene,
        screenshotMonitor: ScreenshotMonitoring,
        screenshotImporter: ScreenshotImportService
    ) {
        self.scene = scene
        self.screenshotMonitor = screenshotMonitor
        self.screenshotImporter = screenshotImporter

        let initialFrame = NotchGeometry.frame(for: scene.notch.mode, on: scene.notch.currentScreen)
        panel = NotchPanel(
            contentRect: initialFrame,
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )
        dropHost = DropHostingView(rootView: NotchRootView(scene: scene))
        configurePanel()
        panel.contentView = dropHost
    }

    /// Shows the panel and starts observing the view model and input.
    func start() {
        observeAndApplyFrame()
        panel.orderFrontRegardless()
        wireDropTarget()
        wireScreenshotMonitor()
        installInteractionMonitors()
        screenshotMonitor.start()
    }

    // MARK: - Panel

    private func configurePanel() {
        panel.level = .statusBar
        panel.collectionBehavior = [.canJoinAllSpaces, .stationary, .ignoresCycle, .fullScreenAuxiliary]
        panel.isOpaque = false
        panel.backgroundColor = .clear
        panel.hasShadow = false
        panel.isMovableByWindowBackground = false
        panel.hidesOnDeactivate = false
        panel.ignoresMouseEvents = false
    }

    /// Re-applies the panel frame whenever `mode` or `currentScreen` changes,
    /// re-arming observation each time (Observation fires once per change).
    private func observeAndApplyFrame() {
        withObservationTracking {
            let mode = viewModel.mode
            let frame = NotchGeometry.frame(for: mode, on: viewModel.currentScreen)
            applyFrame(frame, animated: didApplyInitialFrame)
            didApplyInitialFrame = true
            applyActivation(for: mode)
        } onChange: { [weak self] in
            Task { @MainActor in self?.observeAndApplyFrame() }
        }
    }

    /// Resizes the panel. Mode changes animate the window frame with the same
    /// duration/curve as the SwiftUI content (`NotchStyle.modeTransition`) so the
    /// hardware-notch panel grows/shrinks in lockstep with its contents instead
    /// of snapping.
    private func applyFrame(_ frame: NSRect, animated: Bool) {
        guard animated, frame != panel.frame else {
            panel.setFrame(frame, display: true, animate: false)
            return
        }
        NSAnimationContext.runAnimationGroup { context in
            context.duration = NotchStyle.modeTransitionDuration
            context.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
            context.allowsImplicitAnimation = true
            panel.animator().setFrame(frame, display: true)
        }
    }

    /// When expanded, make the panel key and activate the app so SwiftUI buttons
    /// receive clicks and Share Sheet / AirDrop pop-overs can present. Idle /
    /// dragging stays non-activating so the notch never steals focus.
    private func applyActivation(for mode: NotchMode) {
        if mode == .expanded {
            NSApp.activate(ignoringOtherApps: true)
            panel.makeKeyAndOrderFront(nil)
        } else {
            panel.orderFrontRegardless()
        }
    }

    // MARK: - Input

    private func wireDropTarget() {
        // The drag-destination window fires during real file drags (the global
        // mouse monitor did not). Entering the target = a drag approaching.
        dropHost.onDragMoved = { [weak self] point in
            guard let self else { return }
            if viewModel.mode == .dragging {
                viewModel.dragMoved(to: point)
            } else {
                viewModel.dragApproached(at: point)
            }
        }
        dropHost.onDragExited = { [weak self] in
            guard let self, viewModel.mode == .dragging else { return }
            viewModel.dragCancelled()
        }
        dropHost.onDrop = { [weak self] items in
            self?.viewModel.drop(items: items)
        }
    }

    private func wireScreenshotMonitor() {
        // The monitor delivers on the main thread; import + toast on the main actor.
        screenshotMonitor.onScreenshot = { [weak self] url in
            MainActor.assumeIsolated {
                guard let self, self.screenshotImporter.importScreenshot(at: url) != nil else { return }
                self.scene.notch.showToast(ToastMessage(text: "Screenshot added to Shelf"))
                self.scene.shelf.refresh()
            }
        }
    }

    private func installInteractionMonitors() {
        // Close on a click outside the notch (要件定義.md §5.3 主動線).
        outsideClickMonitor = NSEvent.addGlobalMonitorForEvents(matching: [.leftMouseDown]) { [weak self] _ in
            guard let self, viewModel.mode == .expanded else { return }
            let location = NSEvent.mouseLocation
            if !panel.frame.contains(location) {
                viewModel.collapse()
            }
        }
        // Esc closes (要件定義.md §5.3 補助).
        keyMonitor = NSEvent.addLocalMonitorForEvents(matching: [.keyDown]) { [weak self] event in
            guard let self, event.keyCode == KeyCode.escape, viewModel.mode != .collapsed else { return event }
            viewModel.collapse()
            return nil
        }
    }

    func stop() {
        screenshotMonitor.stop()
        if let outsideClickMonitor {
            NSEvent.removeMonitor(outsideClickMonitor)
        }
        if let keyMonitor {
            NSEvent.removeMonitor(keyMonitor)
        }
        outsideClickMonitor = nil
        keyMonitor = nil
    }

    deinit {
        // Monitors must be removed; `stop()` is idempotent and main-actor only,
        // so callers invoke it explicitly on teardown.
    }
}
