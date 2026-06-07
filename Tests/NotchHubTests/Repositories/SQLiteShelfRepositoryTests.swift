import Foundation
@testable import NotchHub
import Testing

struct SQLiteShelfRepositoryTests {
    private let epoch = Date(timeIntervalSince1970: 1_000_000)

    private func makeRepository() throws -> SQLiteShelfRepository {
        let database = try SQLiteDatabase.inMemory()
        try MigrationRunner(migrations: AppMigrations.shelf).migrate(database)
        return SQLiteShelfRepository(database: database)
    }

    @Test
    func insertAndFetchOrdersPinnedThenNewest() throws {
        let repo = try makeRepository()
        let oldUnpinned = try ShelfItem.text(name: "old", body: "old", createdAt: epoch)
        let newUnpinned = try ShelfItem.text(name: "new", body: "new", createdAt: epoch.addingTimeInterval(100))
        let pinned = try ShelfItem.text(
            name: "pin",
            body: "pin",
            createdAt: epoch.addingTimeInterval(50),
            isPinned: true
        )
        try repo.insert(oldUnpinned)
        try repo.insert(newUnpinned)
        try repo.insert(pinned)

        #expect(try repo.fetchAll().map(\.name) == ["pin", "new", "old"])
    }

    @Test
    func roundTripsTextAndFileItems() throws {
        let repo = try makeRepository()
        let text = try ShelfItem.text(name: "memo", body: "body text", createdAt: epoch)
        let file = try ShelfItem.file(
            name: "a.pdf",
            bookmark: Data([0xDE, 0xAD, 0xBE, 0xEF]),
            originalPath: "/tmp/a.pdf",
            createdAt: epoch.addingTimeInterval(1)
        )
        try repo.insert(text)
        try repo.insert(file)

        let fetched = try repo.fetchAll()
        let fetchedFile = try #require(fetched.first { $0.kind == .file })
        let fetchedText = try #require(fetched.first { $0.kind == .text })
        #expect(fetchedFile.bookmark == Data([0xDE, 0xAD, 0xBE, 0xEF]))
        #expect(fetchedFile.urlString == "/tmp/a.pdf")
        #expect(fetchedText.body == "body text")
    }

    @Test
    func searchMatchesNameBodyAndURL() throws {
        let repo = try makeRepository()
        try repo.insert(ShelfItem.text(name: "Shopping", body: "milk and eggs", createdAt: epoch))
        try repo.insert(ShelfItem.url(
            name: "Repo",
            url: #require(URL(string: "https://github.com/notch/hub")),
            createdAt: epoch.addingTimeInterval(1)
        ))

        #expect(try repo.search(query: "shopping").map(\.name) == ["Shopping"])
        #expect(try repo.search(query: "eggs").map(\.name) == ["Shopping"])
        #expect(try repo.search(query: "github").map(\.name) == ["Repo"])
        #expect(try repo.search(query: "zzz").isEmpty)
    }

    @Test
    func searchTreatsWildcardsLiterally() throws {
        let repo = try makeRepository()
        try repo.insert(ShelfItem.text(name: "100% done", body: "x", createdAt: epoch))
        try repo.insert(ShelfItem.text(name: "nope", body: "y", createdAt: epoch.addingTimeInterval(1)))

        // "%" must match literally, not as a wildcard.
        #expect(try repo.search(query: "100%").map(\.name) == ["100% done"])
    }

    @Test
    func setPinnedAndDelete() throws {
        let repo = try makeRepository()
        let item = try ShelfItem.text(name: "memo", body: "x", createdAt: epoch)
        try repo.insert(item)

        try repo.setPinned(id: item.id, pinned: true)
        #expect(try repo.fetchAll().first?.isPinned == true)

        try repo.delete(id: item.id)
        #expect(try repo.fetchAll().isEmpty)
    }

    @Test
    func deleteAllClearsEverything() throws {
        let repo = try makeRepository()
        try repo.insert(ShelfItem.text(name: "a", body: "a", createdAt: epoch))
        try repo.insert(ShelfItem.text(name: "b", body: "b", createdAt: epoch.addingTimeInterval(1)))
        try repo.deleteAll()
        #expect(try repo.fetchAll().isEmpty)
    }
}
