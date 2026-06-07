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
        },
        Migration(version: 2) { database in
            // Shelf items (要件定義.md §8). Files/folders are held by bookmark;
            // text/url/markdown store content inline.
            try database.exec(
                """
                CREATE TABLE IF NOT EXISTS shelf_items (
                    id         TEXT PRIMARY KEY,
                    kind       TEXT NOT NULL,
                    name       TEXT NOT NULL,
                    created_at REAL NOT NULL,
                    is_pinned  INTEGER NOT NULL DEFAULT 0,
                    body       TEXT,
                    url_string TEXT,
                    bookmark   BLOB
                );
                """
            )
            try database.exec(
                "CREATE INDEX IF NOT EXISTS idx_shelf_order ON shelf_items (is_pinned DESC, created_at DESC);"
            )
        }
    ]
}
