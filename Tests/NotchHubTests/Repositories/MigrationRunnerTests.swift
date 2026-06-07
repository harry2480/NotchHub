@testable import NotchHub
import Testing

struct MigrationRunnerTests {
    private func tableNames(_ database: SQLiteDatabase) throws -> [String] {
        try database
            .query("SELECT name FROM sqlite_master WHERE type = 'table' AND name NOT LIKE 'sqlite_%' ORDER BY name;")
            .compactMap { $0.string("name") }
    }

    @Test
    func appliesAllPendingMigrationsInOrder() throws {
        let database = try SQLiteDatabase.inMemory()
        let runner = MigrationRunner(migrations: [
            Migration(version: 2) { try $0.exec("CREATE TABLE second (id INTEGER);") },
            Migration(version: 1) { try $0.exec("CREATE TABLE first (id INTEGER);") }
        ])

        try runner.migrate(database)

        #expect(try database.userVersion() == 2)
        #expect(try tableNames(database) == ["first", "second"])
    }

    @Test
    func reRunIsNoOp() throws {
        let database = try SQLiteDatabase.inMemory()
        let runner = MigrationRunner(migrations: [
            Migration(version: 1) { try $0.exec("CREATE TABLE first (id INTEGER);") }
        ])

        try runner.migrate(database)
        try runner.migrate(database) // CREATE TABLE would fail if re-applied
        #expect(try database.userVersion() == 1)
    }

    @Test
    func onlyAppliesMigrationsAboveCurrentVersion() throws {
        let database = try SQLiteDatabase.inMemory()
        try database.setUserVersion(1)

        let runner = MigrationRunner(migrations: [
            Migration(version: 1) { _ in Issue.record("v1 must not run when already at v1") },
            Migration(version: 2) { try $0.exec("CREATE TABLE second (id INTEGER);") }
        ])

        try runner.migrate(database)
        #expect(try database.userVersion() == 2)
        #expect(try tableNames(database) == ["second"])
    }

    @Test
    func failedMigrationRollsBackAndPreservesVersion() throws {
        let database = try SQLiteDatabase.inMemory()
        let runner = MigrationRunner(migrations: [
            Migration(version: 1) { try $0.exec("CREATE TABLE first (id INTEGER);") },
            Migration(version: 2) { _ in throw SQLiteDatabase.DatabaseError.step(code: 1, message: "boom") }
        ])

        #expect(throws: SQLiteDatabase.DatabaseError.self) {
            try runner.migrate(database)
        }
        #expect(try database.userVersion() == 1)
        #expect(try tableNames(database) == ["first"])
    }

    @Test
    func appShelfMigrationsCreateMetaTable() throws {
        let database = try SQLiteDatabase.inMemory()
        try MigrationRunner(migrations: AppMigrations.shelf).migrate(database)
        #expect(try tableNames(database).contains("app_meta"))
    }
}
