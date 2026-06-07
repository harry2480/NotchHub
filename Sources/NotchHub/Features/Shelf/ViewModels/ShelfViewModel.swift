import Foundation
import Observation

/// Drives the Shelf tab (要件定義.md §8.11): listing, search and row actions.
/// All data access goes through ``ShelfService``.
@MainActor
@Observable
final class ShelfViewModel {
    private(set) var items: [ShelfItem] = []
    var searchText: String = ""
    private(set) var warning: String?

    private let service: ShelfService

    init(service: ShelfService) {
        self.service = service
    }

    /// Reloads the list applying the current search text (empty = all).
    func refresh() {
        do {
            items = try service.search(searchText)
        } catch {
            Log.shelf.error("Shelf refresh failed: \(error.localizedDescription, privacy: .public)")
            items = []
        }
    }

    /// Called on launch / when the tab appears: prune dangling files and expired
    /// items, then reload.
    func onAppear() {
        _ = try? service.pruneMissingFiles()
        _ = try? service.sweepExpired()
        refresh()
    }

    func togglePin(_ item: ShelfItem) {
        do {
            let result = try service.setPinned(item.id, !item.isPinned)
            warning = result == .limitReached ? "Pinned limit reached (\(ShelfLimits.pinned))" : nil
        } catch {
            Log.shelf.error("Toggle pin failed: \(error.localizedDescription, privacy: .public)")
        }
        refresh()
    }

    func delete(_ item: ShelfItem) {
        try? service.remove(item.id)
        refresh()
    }

    func deleteAll() {
        try? service.removeAll()
        refresh()
    }

    func open(_ item: ShelfItem) {
        try? service.open(item)
    }

    func revealInFinder(_ item: ShelfItem) {
        try? service.revealInFinder(item)
    }

    /// An item provider so a row can be dragged back out (要件定義.md §8.11 再ドラッグ).
    func itemProvider(for item: ShelfItem) -> NSItemProvider {
        if let url = try? service.resolveURL(for: item) {
            return NSItemProvider(object: url as NSURL)
        }
        if let body = item.body {
            return NSItemProvider(object: body as NSString)
        }
        return NSItemProvider()
    }

    func dismissWarning() {
        warning = nil
    }
}
