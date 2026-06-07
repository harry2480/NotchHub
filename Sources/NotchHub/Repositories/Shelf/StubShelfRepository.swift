import Foundation

/// In-memory ``ShelfRepository`` for tests/previews. Mirrors the SQLite
/// ordering (pinned first, then newest).
final class StubShelfRepository: ShelfRepository {
    enum StubError: Error {
        case applyFailed
    }

    private var items: [ShelfItem]
    var failApply = false

    init(items: [ShelfItem] = []) {
        self.items = items
    }

    private func ordered(_ items: [ShelfItem]) -> [ShelfItem] {
        items.sorted { lhs, rhs in
            if lhs.isPinned != rhs.isPinned { return lhs.isPinned && !rhs.isPinned }
            return lhs.createdAt > rhs.createdAt
        }
    }

    func fetchAll() throws -> [ShelfItem] {
        ordered(items)
    }

    func search(query: String) throws -> [ShelfItem] {
        // Mirror the SQLite repository: trim before deciding "empty query".
        let needle = query.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard !needle.isEmpty else { return ordered(items) }
        return ordered(items.filter { $0.searchableText.lowercased().contains(needle) })
    }

    func insert(_ item: ShelfItem) throws {
        items.removeAll { $0.id == item.id }
        items.append(item)
    }

    func apply(insertions: [ShelfItem], deletions: [ShelfItem.ID]) throws {
        if failApply {
            throw StubError.applyFailed
        }
        var updated = items
        let deletionSet = Set(deletions)
        updated.removeAll { deletionSet.contains($0.id) }
        for item in insertions {
            updated.removeAll { $0.id == item.id }
            updated.append(item)
        }
        items = updated
    }

    func delete(id: ShelfItem.ID) throws {
        items.removeAll { $0.id == id }
    }

    func deleteAll() throws {
        items.removeAll()
    }

    func setPinned(id: ShelfItem.ID, pinned: Bool) throws {
        guard let index = items.firstIndex(where: { $0.id == id }) else { return }
        items[index].isPinned = pinned
    }
}
