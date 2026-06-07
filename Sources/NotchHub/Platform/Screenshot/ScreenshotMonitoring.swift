import Foundation

/// Watches for newly captured screenshots (要件定義.md §9), hiding the
/// file-system watcher behind a protocol. `onScreenshot` is delivered on the
/// main thread.
protocol ScreenshotMonitoring: AnyObject {
    var onScreenshot: ((URL) -> Void)? { get set }
    func start()
    func stop()
}
