import Foundation

/// Test/preview ``ScreenshotMonitoring`` driven manually.
final class StubScreenshotMonitor: ScreenshotMonitoring {
    var onScreenshot: ((URL) -> Void)?
    private(set) var isRunning = false

    func start() {
        isRunning = true
    }

    func stop() {
        isRunning = false
    }

    func emit(_ url: URL) {
        guard isRunning else { return }
        onScreenshot?(url)
    }
}
