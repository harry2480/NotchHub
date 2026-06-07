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
        _ = try add([item])
    }

    /// Adds a drop as one atomic repository mutation. Returns the IDs that remain
    /// after enforcing the regular-item limit.
    @discardableResult
    func add(_ items: [ShelfItem]) throws -> [ShelfItem.ID] {
        guard !items.isEmpty else { return [] }
        let existing = try repository.fetchAll()
        var desired = existing
        for item in items {
            desired.removeAll { $0.id == item.id }
            desired.append(item)
        }

        let unpinned = desired.filter { !$0.isPinned }
        let overflow = max(0, unpinned.count - ShelfLimits.regular)
        let evictedIDs = Set(
            unpinned
                .sorted { $0.createdAt < $1.createdAt }
                .prefix(overflow)
                .map(\.id)
        )
        let insertions = items.filter { !evictedIDs.contains($0.id) }
        let existingIDs = Set(existing.map(\.id))
        let deletions = evictedIDs.filter { existingIDs.contains($0) }

        try repository.apply(insertions: insertions, deletions: Array(deletions))
        if !evictedIDs.isEmpty {
            Log.shelf.info("Evicted \(evictedIDs.count) oldest unpinned Shelf item(s) to respect the limit")
        }
        return insertions.map(\.id)
    }

    /// Pins/unpins an item. Pinning is refused (without error) when the pinned
    /// limit is reached (要件定義.md §8.10 ピン留め: 警告のみ).
    @discardableResult
    func setPinned(_ id: ShelfItem.ID, _ pinned: Bool) throws -> PinResult {
        if pinned {
            let current = try repository.fetchAll()
            // Re-pinning an already-pinned item is idempotent and must not be
            // refused by the limit (the count would include the item itself).
            if current.first(where: { $0.id == id })?.isPinned == true { return .pinned }
            guard current.filter(\.isPinned).count < ShelfLimits.pinned else { return .limitReached }
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
            do {
                _ = try bookmarkResolver.resolve(bookmark)
            } catch BookmarkError.fileMissing {
                // Only the original-file-deleted case removes the item; transient
                // / permission / format errors keep it (avoid false deletion).
                try repository.delete(id: item.id)
                removed.append(item.id)
            } catch {
                let details = error.localizedDescription
                Log.shelf
                    .error(
                        "Skipping prune for \(item.name, privacy: .public): \(details, privacy: .public)"
                    )
            }
        }
        return removed
    }
}
