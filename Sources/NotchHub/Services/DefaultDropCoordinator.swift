import Foundation

/// Production ``DropCoordinating`` (Phase 2): the Shelf zone persists items via
/// ``ShelfService``; Share / AirDrop remain placeholders until Phase 3. Undo
/// removes the items inserted by the most recent Shelf drop (要件定義.md §7.4).
final class DefaultDropCoordinator: DropCoordinating {
    private let shelfService: ShelfService
    private let itemFactory: ShelfItemFactory
    private var lastInsertedIDs: [ShelfItem.ID] = []

    init(shelfService: ShelfService, itemFactory: ShelfItemFactory) {
        self.shelfService = shelfService
        self.itemFactory = itemFactory
    }

    func handle(_ request: DropRequest) -> ToastMessage {
        switch request.zone {
        case .shelf:
            addToShelf(request.items)
        case .share:
            ToastMessage(text: "Opening Share…")
        case .airDrop:
            ToastMessage(text: "Opening AirDrop…")
        }
    }

    func undo(_ request: DropRequest) {
        guard request.zone == .shelf else { return }
        for id in lastInsertedIDs {
            try? shelfService.remove(id)
        }
        lastInsertedIDs = []
    }

    private func addToShelf(_ dropped: [DroppedItem]) -> ToastMessage {
        do {
            let items = try itemFactory.makeItems(from: dropped)
            for item in items {
                try shelfService.add(item)
            }
            lastInsertedIDs = items.map(\.id)
            let count = items.count
            return ToastMessage(text: "Added \(count) to Shelf", isUndoable: true)
        } catch {
            Log.shelf.error("Failed to add to Shelf: \(error.localizedDescription, privacy: .public)")
            return ToastMessage(text: "Couldn't add to Shelf")
        }
    }
}
