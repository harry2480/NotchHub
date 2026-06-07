/// Applies forward-only migrations to a database based on its `user_version`.
///
/// Each pending migration (whose `version` exceeds the current `user_version`)
/// runs inside a transaction together with the `user_version` bump, so a failed
/// migration leaves the database untouched. Re-running is a no-op once every
/// migration has been applied.
struct MigrationRunner {
    private let migrations: [Migration]

    init(migrations: [Migration]) {
        self.migrations = migrations.sorted { $0.version < $1.version }
    }

    func migrate(_ database: SQLiteDatabase) throws {
        let current = try database.userVersion()
        for migration in migrations where migration.version > current {
            try database.transaction {
                try migration.apply(database)
                try database.setUserVersion(migration.version)
            }
            Log.database.info("Applied migration v\(migration.version, privacy: .public)")
        }
    }
}
