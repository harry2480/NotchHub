import Foundation
@testable import NotchHub
import Testing

struct SQLiteAirDropHistoryRepositoryTests {
    private let epoch = Date(timeIntervalSince1970: 1_000_000)

    private func makeRepository() throws -> SQLiteAirDropHistoryRepository {
        let database = try SQLiteDatabase.inMemory()
        try MigrationRunner(migrations: AppMigrations.airDropHistory).migrate(database)
        return SQLiteAirDropHistoryRepository(database: database)
    }

    @Test
    func insertAndFetchNewestFirst() throws {
        let repo = try makeRepository()
        try repo.insert(AirDropRecord(name: "old", kind: .file, date: epoch, originalPath: "/a", outcome: .sent))
        try repo.insert(AirDropRecord(
            name: "new",
            kind: .text,
            date: epoch.addingTimeInterval(100),
            outcome: .failed
        ))

        let records = try repo.fetchAll()
        #expect(records.map(\.name) == ["new", "old"])
        #expect(records.first?.outcome == .failed)
        #expect(records.last?.originalPath == "/a")
    }

    @Test
    func roundTripsOutcomeAndKind() throws {
        let repo = try makeRepository()
        try repo.insert(AirDropRecord(name: "doc", kind: .folder, date: epoch, outcome: .cancelled))
        let record = try #require(try repo.fetchAll().first)
        #expect(record.kind == .folder)
        #expect(record.outcome == .cancelled)
        #expect(record.originalPath == nil)
    }

    @Test
    func deleteAllClears() throws {
        let repo = try makeRepository()
        try repo.insert(AirDropRecord(name: "a", kind: .file, date: epoch, outcome: .sent))
        try repo.deleteAll()
        #expect(try repo.fetchAll().isEmpty)
    }
}
