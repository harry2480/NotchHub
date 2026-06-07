import Foundation

/// SQLite-backed ``ShelfRepository`` (`shelf_items` table, created by migration
/// v2). Rows are mapped to ``ShelfItem`` via its validating initializer so the
/// SQLite representation never leaks above this layer.
final class SQLiteShelfRepository: ShelfRepository {
    private let database: SQLiteDatabase

    init(database: SQLiteDatabase) {
        self.database = database
    }

    private static let columns = "id, kind, name, created_at, is_pinned, body, url_string, bookmark"
    private static let orderClause = "ORDER BY is_pinned DESC, created_at DESC"

    func fetchAll() throws -> [ShelfItem] {
        try database
            .query("SELECT \(Self.columns) FROM shelf_items \(Self.orderClause);")
            .compactMap(Self.item(from:))
    }

    func search(query: String) throws -> [ShelfItem] {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return try fetchAll() }
        let pattern = "%\(Self.escapeLike(trimmed))%"
        let sql = """
        SELECT \(Self.columns) FROM shelf_items
        WHERE name LIKE ?1 ESCAPE '\\'
           OR IFNULL(body, '') LIKE ?1 ESCAPE '\\'
           OR IFNULL(url_string, '') LIKE ?1 ESCAPE '\\'
        \(Self.orderClause);
        """
        return try database.query(sql, [.text(pattern)]).compactMap(Self.item(from:))
    }

    func insert(_ item: ShelfItem) throws {
        try database.run(
            """
            INSERT OR REPLACE INTO shelf_items
            (id, kind, name, created_at, is_pinned, body, url_string, bookmark)
            VALUES (?, ?, ?, ?, ?, ?, ?, ?);
            """,
            [
                .text(item.id.uuidString),
                .text(item.kind.rawValue),
                .text(item.name),
                .real(item.createdAt.timeIntervalSince1970),
                .integer(item.isPinned ? 1 : 0),
                .optional(item.body),
                .optional(item.urlString),
                .optional(item.bookmark)
            ]
        )
    }

    func apply(insertions: [ShelfItem], deletions: [ShelfItem.ID]) throws {
        try database.transaction {
            for id in deletions {
                try delete(id: id)
            }
            for item in insertions {
                try insert(item)
            }
        }
    }

    func delete(id: ShelfItem.ID) throws {
        try database.run("DELETE FROM shelf_items WHERE id = ?;", [.text(id.uuidString)])
    }

    func deleteAll() throws {
        try database.run("DELETE FROM shelf_items;")
    }

    func setPinned(id: ShelfItem.ID, pinned: Bool) throws {
        try database.run(
            "UPDATE shelf_items SET is_pinned = ? WHERE id = ?;",
            [.integer(pinned ? 1 : 0), .text(id.uuidString)]
        )
    }

    // MARK: - Mapping

    private static func item(from row: SQLiteRow) -> ShelfItem? {
        guard
            let idString = row.string("id"),
            let id = UUID(uuidString: idString),
            let kindRaw = row.string("kind"),
            let kind = ShelfItemKind(rawValue: kindRaw),
            let name = row.string("name"),
            let createdAt = row.double("created_at")
        else {
            Log.shelf.error("Skipping unmappable shelf row")
            return nil
        }
        return try? ShelfItem(
            id: id,
            kind: kind,
            name: name,
            createdAt: Date(timeIntervalSince1970: createdAt),
            isPinned: row.bool("is_pinned") ?? false,
            body: row.string("body"),
            urlString: row.string("url_string"),
            bookmark: row.data("bookmark")
        )
    }

    /// Escapes LIKE wildcards so a user's `%` / `_` / `\` are treated literally.
    private static func escapeLike(_ text: String) -> String {
        text
            .replacingOccurrences(of: "\\", with: "\\\\")
            .replacingOccurrences(of: "%", with: "\\%")
            .replacingOccurrences(of: "_", with: "\\_")
    }
}
