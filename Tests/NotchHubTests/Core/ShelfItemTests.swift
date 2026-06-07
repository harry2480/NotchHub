import Foundation
@testable import NotchHub
import Testing

struct ShelfItemTests {
    private let date = Date(timeIntervalSince1970: 1_000_000)

    @Test
    func textFactoryRequiresBody() {
        #expect(throws: ShelfItem.ValidationError.missingBody) {
            try ShelfItem(kind: .text, name: "memo", createdAt: date, body: nil)
        }
    }

    @Test
    func fileKindRequiresBookmark() {
        #expect(throws: ShelfItem.ValidationError.missingBookmark) {
            try ShelfItem(kind: .file, name: "a.pdf", createdAt: date, bookmark: nil)
        }
    }

    @Test
    func urlKindRequiresURLString() {
        #expect(throws: ShelfItem.ValidationError.missingURL) {
            try ShelfItem(kind: .url, name: "site", createdAt: date)
        }
    }

    @Test
    func emptyNameIsRejected() {
        #expect(throws: ShelfItem.ValidationError.emptyName) {
            try ShelfItem(kind: .text, name: "  ", createdAt: date, body: "x")
        }
    }

    @Test
    func factoriesProduceValidItems() throws {
        let text = try ShelfItem.text(name: "memo", body: "hello", createdAt: date)
        #expect(text.kind == .text)
        let url = try ShelfItem.url(name: "site", url: #require(URL(string: "https://example.com")), createdAt: date)
        #expect(url.kind == .url)
        #expect(url.urlString == "https://example.com")
        let file = try ShelfItem.file(name: "a.pdf", bookmark: Data([1]), createdAt: date)
        #expect(file.kind == .file)
    }

    @Test
    func searchableTextCombinesFields() throws {
        let item = try ShelfItem.url(
            name: "Example",
            url: #require(URL(string: "https://example.com/path")),
            createdAt: date
        )
        #expect(item.searchableText.contains("Example"))
        #expect(item.searchableText.contains("example.com"))
    }
}

struct ShelfLifespanTests {
    private let created = Date(timeIntervalSince1970: 1_000_000)

    @Test
    func foreverNeverExpires() {
        #expect(ShelfLifespan.forever.expiryDate(from: created) == nil)
        #expect(!ShelfLifespan.forever.isExpired(createdAt: created, now: created.addingTimeInterval(10_000_000)))
    }

    @Test
    func daysExpiryIsComputed() {
        let sevenDays = ShelfLifespan.sevenDays
        let expiry = sevenDays.expiryDate(from: created)
        #expect(expiry == created.addingTimeInterval(7 * 86400))
    }

    @Test
    func isExpiredAtBoundary() {
        let lifespan = ShelfLifespan.days(1)
        let justBefore = created.addingTimeInterval(86400 - 1)
        let atExpiry = created.addingTimeInterval(86400)
        #expect(!lifespan.isExpired(createdAt: created, now: justBefore))
        #expect(lifespan.isExpired(createdAt: created, now: atExpiry))
    }
}
