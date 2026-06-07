import AppKit
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
    private let screenProvider: ScreenProviding
    private let dragMonitor: GlobalDragMonitoring
    private let screenshotMonitor: ScreenshotMonitoring
    private let screenshotImporter: ScreenshotImportService
    private let panel: NSPanel

    private var viewModel: NotchViewModel {
        scene.notch
    }

    private var outsideClickMonitor: Any?
    private var keyMonitor: Any?

    init(
        scene: NotchScene,
        screenProvider: ScreenProviding,
        dragMonitor: GlobalDragMonitoring,
        screenshotMonitor: ScreenshotMonitoring,
        screenshotImporter: ScreenshotImportService
    ) {
        self.scene = scene
        self.screenProvider = screenProvider
        self.dragMonitor = dragMonitor
        self.screenshotMonitor = screenshotMonitor
        self.screenshotImporter = screenshotImporter

        let initialFrame = NotchGeometry.frame(for: scene.notch.mode, on: scene.notch.currentScreen)
        panel = NSPanel(
            contentRect: initialFrame,
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )
        configurePanel()
        panel.contentView = NSHostingView(rootView: NotchRootView(scene: scene))
    }

    /// Shows the panel and starts observing the view model and input.
    func start() {
        observeAndApplyFrame()
        panel.orderFrontRegardless()
        wireDragMonitor()
        wireScreenshotMonitor()
        installInteractionMonitors()
        dragMonitor.start()
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
            let frame = NotchGeometry.frame(for: viewModel.mode, on: viewModel.currentScreen)
            panel.setFrame(frame, display: true, animate: false)
        } onChange: { [weak self] in
            Task { @MainActor in self?.observeAndApplyFrame() }
        }
    }

    // MARK: - Input

    private func wireDragMonitor() {
        dragMonitor.onDragMoved = { [weak self] point in
            guard let self else { return }
            if viewModel.mode == .dragging {
                viewModel.dragMoved(to: point)
            } else if let screen = screenProvider.screen(containing: point),
                      NotchGeometry.isApproaching(point, on: screen) {
                viewModel.dragApproached(at: point)
            }
        }
        dragMonitor.onDragEnded = {
            // A drop landing on the panel is handled by NotchDropDelegate; only
            // cancel if the drag ended without a drop (still in dragging mode).
            // Deferred a tick so an in-flight drop wins the race.
            Task { @MainActor [weak self] in
                guard let self, viewModel.mode == .dragging else { return }
                viewModel.dragCancelled()
            }
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
        dragMonitor.stop()
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
