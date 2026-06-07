import Foundation

/// In-memory ``ShelfRepository`` for tests/previews. Mirrors the SQLite
/// ordering (pinned first, then newest).
final class StubShelfRepository: ShelfRepository {
    private var items: [ShelfItem]

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
        let needle = query.lowercased()
        guard !needle.isEmpty else { return ordered(items) }
        return ordered(items.filter { $0.searchableText.lowercased().contains(needle) })
    }

    func insert(_ item: ShelfItem) throws {
        items.removeAll { $0.id == item.id }
        items.append(item)
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
