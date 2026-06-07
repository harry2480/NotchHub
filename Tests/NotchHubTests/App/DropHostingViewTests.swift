import AppKit
import Foundation
@testable import NotchHub
import Testing

@MainActor
struct DropHostingViewTests {
    private func makePasteboard() -> NSPasteboard {
        let pasteboard = NSPasteboard(name: NSPasteboard.Name("com.harry.notchhub.test.\(UUID().uuidString)"))
        pasteboard.clearContents()
        return pasteboard
    }

    @Test
    func parsesFileURL() {
        let pasteboard = makePasteboard()
        let url = URL(fileURLWithPath: "/tmp/report.pdf")
        pasteboard.writeObjects([url as NSURL])
        #expect(DropHostingView.items(from: pasteboard) == [.fileURL(url)])
    }

    @Test
    func parsesWebURL() throws {
        let pasteboard = makePasteboard()
        let url = try #require(URL(string: "https://example.com"))
        pasteboard.writeObjects([url as NSURL])
        #expect(DropHostingView.items(from: pasteboard) == [.url(url)])
    }

    @Test
    func parsesPlainText() {
        let pasteboard = makePasteboard()
        pasteboard.writeObjects(["hello world" as NSString])
        #expect(DropHostingView.items(from: pasteboard) == [.text("hello world")])
    }

    @Test
    func emptyPasteboardYieldsNoItems() {
        #expect(DropHostingView.items(from: makePasteboard()).isEmpty)
    }
}
