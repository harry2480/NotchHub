import Foundation

/// Shelf business rules over a ``ShelfRepository`` (要件定義.md §8): capacity
/// limits, lifespan expiry, pinning and auto-removal of items whose original
/// file is gone. The repository handles storage/ordering; this owns the policy.
final class ShelfService {
    /// Outcome of attempting to pin an item.
    enum PinResult: Equatable {
        case pinned
        case unpinned
        case limitReached
    }

    private let repository: ShelfRepository
    private let bookmarkResolver: BookmarkResolving
    private let workspace: WorkspaceOpening
    private let lifespan: ShelfLifespan
    private let now: () -> Date

    init(
        repository: ShelfRepository,
        bookmarkResolver: BookmarkResolving,
        workspace: WorkspaceOpening,
        lifespan: ShelfLifespan = .forever,
        now: @escaping () -> Date = Date.init
    ) {
        self.repository = repository
        self.bookmarkResolver = bookmarkResolver
        self.workspace = workspace
        self.lifespan = lifespan
        self.now = now
    }

    func items() throws -> [ShelfItem] {
        try repository.fetchAll()
    }

    func search(_ query: String) throws -> [ShelfItem] {
        try repository.search(query: query)
    }

    /// Adds a new (unpinned) item, evicting the oldest unpinned item first if
    /// the regular limit is reached (要件定義.md §8.10 通常: 最古の未ピン留めから削除).
    func add(_ item: ShelfItem) throws {
        let existing = try repository.fetchAll()
        let unpinned = existing.filter { !$0.isPinned }
        if unpinned.count >= ShelfLimits.regular, let oldest = unpinned.min(by: { $0.createdAt < $1.createdAt }) {
            try repository.delete(id: oldest.id)
            Log.shelf.info("Evicted oldest unpinned shelf item to respect the limit")
        }
        try repository.insert(item)
    }

    /// Pins/unpins an item. Pinning is refused (without error) when the pinned
    /// limit is reached (要件定義.md §8.10 ピン留め: 警告のみ).
    @discardableResult
    func setPinned(_ id: ShelfItem.ID, _ pinned: Bool) throws -> PinResult {
        if pinned {
            let pinnedCount = try repository.fetchAll().filter(\.isPinned).count
            guard pinnedCount < ShelfLimits.pinned else { return .limitReached }
            try repository.setPinned(id: id, pinned: true)
            return .pinned
        } else {
            try repository.setPinned(id: id, pinned: false)
            return .unpinned
        }
    }

    func remove(_ id: ShelfItem.ID) throws {
        try repository.delete(id: id)
    }

    func removeAll() throws {
        try repository.deleteAll()
    }

    /// Resolves the file/URL an item points to (for open / reveal / re-drag).
    func resolveURL(for item: ShelfItem) throws -> URL? {
        if let bookmark = item.bookmark {
            return try bookmarkResolver.resolve(bookmark).url
        }
        if item.kind == .url, let urlString = item.urlString {
            return URL(string: urlString)
        }
        return nil
    }

    /// Opens an item in its default app / browser (要件定義.md §8.11 開く).
    func open(_ item: ShelfItem) throws {
        guard let url = try resolveURL(for: item) else { return }
        workspace.open(url)
    }

    /// Reveals a file-backed item in Finder (要件定義.md §8.11 Finder 表示).
    func revealInFinder(_ item: ShelfItem) throws {
        guard let url = try resolveURL(for: item) else { return }
        workspace.revealInFinder(url)
    }

    /// Deletes expired, unpinned items (要件定義.md §8.9). Pinned items never
    /// expire. Returns the removed ids.
    @discardableResult
    func sweepExpired() throws -> [ShelfItem.ID] {
        let current = now()
        let expired = try repository.fetchAll().filter {
            !$0.isPinned && lifespan.isExpired(createdAt: $0.createdAt, now: current)
        }
        for item in expired {
            try repository.delete(id: item.id)
        }
        return expired.map(\.id)
    }

    /// Removes file-backed items whose original file no longer resolves
    /// (要件定義.md §8.3 元ファイル削除時は自動削除). Returns the removed ids.
    @discardableResult
    func pruneMissingFiles() throws -> [ShelfItem.ID] {
        var removed: [ShelfItem.ID] = []
        for item in try repository.fetchAll() where item.kind.isFileBacked {
            guard let bookmark = item.bookmark else { continue }
            if (try? bookmarkResolver.resolve(bookmark)) == nil {
                try repository.delete(id: item.id)
                removed.append(item.id)
            }
        }
        return removed
    }
}
