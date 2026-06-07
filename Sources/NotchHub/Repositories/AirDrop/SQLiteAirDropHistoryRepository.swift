import Foundation

/// SQLite-backed ``AirDropHistoryRepository`` (`airdrop_history` table in
/// `airdrop_history.db`). The recipient is deliberately absent from the schema
/// (要件定義.md §10.5 保存しない: 送信先).
final class SQLiteAirDropHistoryRepository: AirDropHistoryRepository {
    private let database: SQLiteDatabase

    init(database: SQLiteDatabase) {
        self.database = database
    }

    func fetchAll() throws -> [AirDropRecord] {
        try database
            .query("SELECT id, name, kind, date, original_path, outcome FROM airdrop_history ORDER BY date DESC;")
            .compactMap(Self.record(from:))
    }

    func insert(_ record: AirDropRecord) throws {
        try database.run(
            """
            INSERT OR REPLACE INTO airdrop_history (id, name, kind, date, original_path, outcome)
            VALUES (?, ?, ?, ?, ?, ?);
            """,
            [
                .text(record.id.uuidString),
                .text(record.name),
                .text(record.kind.rawValue),
                .real(record.date.timeIntervalSince1970),
                .optional(record.originalPath),
                .text(record.outcome.rawValue)
            ]
        )
    }

    func deleteAll() throws {
        try database.run("DELETE FROM airdrop_history;")
    }

    private static func record(from row: SQLiteRow) -> AirDropRecord? {
        guard
            let idString = row.string("id"),
            let id = UUID(uuidString: idString),
            let name = row.string("name"),
            let kindRaw = row.string("kind"),
            let kind = ShelfItemKind(rawValue: kindRaw),
            let date = row.double("date"),
            let outcomeRaw = row.string("outcome"),
            let outcome = ShareOutcome(rawValue: outcomeRaw)
        else {
            Log.shelf.error("Skipping unmappable airdrop_history row")
            return nil
        }
        return AirDropRecord(
            id: id,
            name: name,
            kind: kind,
            date: Date(timeIntervalSince1970: date),
            originalPath: row.string("original_path"),
            outcome: outcome
        )
    }
}
