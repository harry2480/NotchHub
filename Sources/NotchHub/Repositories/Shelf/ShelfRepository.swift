import Foundation

/// Persistence for Shelf items (リポジトリ層設計規約.md). Results are returned
/// already ordered (pinned first, then newest — 要件定義.md §8.7). The Service
/// owns the business rules (limits / lifespan); the repository only runs
/// queries and maps rows to ``ShelfItem``.
protocol ShelfRepository {
    func fetchAll() throws -> [ShelfItem]
    func search(query: String) throws -> [ShelfItem]
    func insert(_ item: ShelfItem) throws
    func apply(insertions: [ShelfItem], deletions: [ShelfItem.ID]) throws
    func delete(id: ShelfItem.ID) throws
    func deleteAll() throws
    func setPinned(id: ShelfItem.ID, pinned: Bool) throws
}
