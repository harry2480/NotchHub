/// Migration catalogues for each NotchHub database.
///
/// Migrations are forward-only and never edited once shipped: later schema
/// changes are appended as new versions. The Shelf / settings / history tables
/// arrive in their respective phases; v1 establishes a small metadata table so
/// the migration mechanism is exercised from the very first launch.
enum AppMigrations {
    static let shelf: [Migration] = [
        Migration(version: 1) { database in
            try database.exec(
                """
                CREATE TABLE IF NOT EXISTS app_meta (
                    key   TEXT PRIMARY KEY,
                    value TEXT NOT NULL
                );
                """
            )
        }
    ]
}
