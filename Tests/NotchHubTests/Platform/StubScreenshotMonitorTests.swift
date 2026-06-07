import Foundation
@testable import NotchHub
import Testing

struct StubScreenshotMonitorTests {
    @Test
    func emitsOnlyWhileRunning() {
        let monitor = StubScreenshotMonitor()
        let url = URL(fileURLWithPath: "/tmp/shot.png")
        var received: [URL] = []
        monitor.onScreenshot = { received.append($0) }

        monitor.emit(url)
        monitor.start()
        monitor.emit(url)
        monitor.stop()
        monitor.emit(url)

        #expect(received == [url])
    }
}
