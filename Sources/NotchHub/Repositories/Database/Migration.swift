/// A single forward-only schema migration.
///
/// `version` must be strictly increasing across an app's migration list and is
/// compared against SQLite's `user_version` (リポジトリ層設計規約.md). `apply`
/// performs the schema change; it runs inside a transaction managed by
/// ``MigrationRunner``.
struct Migration {
    let version: Int
    let apply: (SQLiteDatabase) throws -> Void
}
