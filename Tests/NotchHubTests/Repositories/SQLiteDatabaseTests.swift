import Foundation
@testable import NotchHub
import Testing

struct SQLiteDatabaseTests {
    private func makeDatabase() throws -> SQLiteDatabase {
        let database = try SQLiteDatabase.inMemory()
        try database.exec(
            """
            CREATE TABLE item (
                id    INTEGER PRIMARY KEY AUTOINCREMENT,
                name  TEXT NOT NULL,
                score REAL,
                blob  BLOB,
                note  TEXT
            );
            """
        )
        return database
    }

    @Test
    func runInsertReturnsRowID() throws {
        let database = try makeDatabase()
        let first = try database.run("INSERT INTO item (name, score) VALUES (?, ?);", [.text("alpha"), .real(1.5)])
        let second = try database.run("INSERT INTO item (name, score) VALUES (?, ?);", [.text("beta"), .real(2.0)])
        #expect(first == 1)
        #expect(second == 2)
    }

    @Test
    func queryReadsTypedValues() throws {
        let database = try makeDatabase()
        let payload = Data([0x01, 0x02, 0x03])
        try database.run(
            "INSERT INTO item (name, score, blob, note) VALUES (?, ?, ?, ?);",
            [.text("gamma"), .real(3.5), .blob(payload), .null]
        )

        let rows = try database.query("SELECT id, name, score, blob, note FROM item;")
        #expect(rows.count == 1)
        let row = try #require(rows.first)
        #expect(row.int("id") == 1)
        #expect(row.string("name") == "gamma")
        #expect(row.double("score") == 3.5)
        #expect(row.data("blob") == payload)
        #expect(row.string("note") == nil)
        #expect(row["note"] == .null)
    }

    @Test
    func parametersPreventInjection() throws {
        let database = try makeDatabase()
        let malicious = "x'); DROP TABLE item; --"
        try database.run("INSERT INTO item (name) VALUES (?);", [.text(malicious)])

        let rows = try database.query("SELECT name FROM item;")
        #expect(rows.first?.string("name") == malicious)
    }

    @Test
    func transactionRollsBackOnError() throws {
        let database = try makeDatabase()
        try database.run("INSERT INTO item (name) VALUES (?);", [.text("keep")])

        struct Boom: Error {}
        #expect(throws: Boom.self) {
            try database.transaction {
                try database.run("INSERT INTO item (name) VALUES (?);", [.text("discard")])
                throw Boom()
            }
        }

        let rows = try database.query("SELECT name FROM item ORDER BY id;")
        #expect(rows.compactMap { $0.string("name") } == ["keep"])
    }

    @Test
    func bindingMoreParametersThanPlaceholdersThrows() throws {
        let database = try SQLiteDatabase.inMemory()
        // "SELECT 1" has no bind placeholders, so binding a parameter at index 1
        // fails (SQLITE_RANGE). The prepared statement must be finalized rather
        // than leaked, and the error surfaces to the caller.
        #expect(throws: SQLiteDatabase.DatabaseError.self) {
            try database.query("SELECT 1;", [.text("orphan")])
        }
    }

    @Test
    func userVersionRoundTrips() throws {
        let database = try SQLiteDatabase.inMemory()
        #expect(try database.userVersion() == 0)
        try database.setUserVersion(7)
        #expect(try database.userVersion() == 7)
    }
}
