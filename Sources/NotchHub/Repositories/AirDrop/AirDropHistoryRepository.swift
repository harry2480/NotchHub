import Foundation

/// Persistence for AirDrop history (要件定義.md §10.5). Records are returned
/// newest-first. The recipient is never part of the model, so it cannot be
/// stored.
protocol AirDropHistoryRepository {
    func fetchAll() throws -> [AirDropRecord]
    func insert(_ record: AirDropRecord) throws
    func deleteAll() throws
}
