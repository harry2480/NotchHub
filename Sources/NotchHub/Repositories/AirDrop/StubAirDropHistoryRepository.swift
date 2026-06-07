import Foundation

/// In-memory ``AirDropHistoryRepository`` for tests/previews.
final class StubAirDropHistoryRepository: AirDropHistoryRepository {
    private(set) var records: [AirDropRecord]

    init(records: [AirDropRecord] = []) {
        self.records = records
    }

    func fetchAll() throws -> [AirDropRecord] {
        records.sorted { $0.date > $1.date }
    }

    func insert(_ record: AirDropRecord) throws {
        records.append(record)
    }

    func deleteAll() throws {
        records.removeAll()
    }
}
