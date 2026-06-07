import Foundation
@testable import NotchHub
import Testing

struct ShelfItemFactoryTests {
    private let now = { Date(timeIntervalSince1970: 1_000_000) }

    private func makeFactory() -> ShelfItemFactory {
        ShelfItemFactory(bookmarkResolver: StubBookmarkResolver(), now: now)
    }

    @Test
    func fileURLBecomesFileItemWithBookmark() throws {
        let item = try makeFactory().makeItem(from: .fileURL(URL(fileURLWithPath: "/tmp/report.pdf")))
        #expect(item.kind == .file)
        #expect(item.name == "report.pdf")
        #expect(item.bookmark != nil)
    }

    @Test
    func directoryBecomesFolder() throws {
        let item = try makeFactory().makeItem(from: .fileURL(URL(fileURLWithPath: "/tmp/project", isDirectory: true)))
        #expect(item.kind == .folder)
    }

    @Test
    func imageExtensionBecomesImage() throws {
        let item = try makeFactory().makeItem(from: .fileURL(URL(fileURLWithPath: "/tmp/shot.PNG")))
        #expect(item.kind == .image)
    }

    @Test
    func urlBecomesURLItemNamedByHost() throws {
        let item = try makeFactory().makeItem(from: .url(#require(URL(string: "https://github.com/a/b"))))
        #expect(item.kind == .url)
        #expect(item.name == "github.com")
    }

    @Test
    func textBecomesTextItemTitledByFirstLine() throws {
        let item = try makeFactory().makeItem(from: .text("first line\nsecond line"))
        #expect(item.kind == .text)
        #expect(item.name == "first line")
        #expect(item.body == "first line\nsecond line")
    }

    @Test
    func longTextTitleIsTruncated() {
        let title = ShelfItemFactory.title(forText: String(repeating: "a", count: 100))
        #expect(title.count <= 41) // 40 chars + ellipsis
        #expect(title.hasSuffix("…"))
    }

    @Test
    func emptyTextTitleFallsBack() {
        #expect(ShelfItemFactory.title(forText: "\n\n") == "Untitled")
    }

    @Test
    func textTitleUsesFirstNonEmptyTrimmedLine() {
        #expect(ShelfItemFactory.title(forText: "   \n  second line  ") == "second line")
    }
}
