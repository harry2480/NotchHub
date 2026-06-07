import Foundation

/// Composition Root — the single place where concrete implementations are wired
/// to their protocols (アーキテクチャ.md). No other layer constructs adapters or
/// repositories directly.
///
/// Phase 0 wires the Launch-at-Login manager and opens the Shelf database,
/// applying pending migrations. Later phases extend `bootstrap()` with the
/// repositories, services and view models they introduce.
final class AppComposition {
    let loginItemManager: LoginItemManaging

    private(set) var shelfDatabase: SQLiteDatabase?

    /// - Parameter loginItemManager: injectable for tests; defaults to the
    ///   production `SMAppService`-backed manager.
    init(loginItemManager: LoginItemManaging = SMAppServiceLoginItemManager()) {
        self.loginItemManager = loginItemManager
    }

    /// Opens databases and applies migrations. Call once at launch.
    func bootstrap() throws {
        let databaseURL = try AppPaths.databaseURL(named: "shelf.db")
        let database = try SQLiteDatabase(path: databaseURL.path)
        try MigrationRunner(migrations: AppMigrations.shelf).migrate(database)
        shelfDatabase = database
        Log.app.info("Composition bootstrap complete")
    }
}
