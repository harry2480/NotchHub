import Foundation

/// Production ``DropCoordinating``: the Shelf zone persists items via
/// ``ShelfService``; the Share / AirDrop zones present the macOS sheets via
/// ``ShareService``. Undo removes the items inserted by the most recent Shelf
/// drop (要件定義.md §7.4).
final class DefaultDropCoordinator: DropCoordinating {
    private let shelfService: ShelfService
    private let shareService: ShareService
    private let itemFactory: ShelfItemFactory
    private var lastInsertedIDs: [ShelfItem.ID] = []

    init(shelfService: ShelfService, shareService: ShareService, itemFactory: ShelfItemFactory) {
        self.shelfService = shelfService
        self.shareService = shareService
        self.itemFactory = itemFactory
    }

    func handle(_ request: DropRequest) -> ToastMessage {
        switch request.zone {
        case .shelf:
            addToShelf(request.items)
        case .share:
            present(request.items, via: shareService.share, label: "Share")
        case .airDrop:
            present(request.items, via: shareService.airDrop, label: "AirDrop")
        }
    }

    private func present(
        _ items: [DroppedItem],
        via action: ([DroppedItem]) throws -> Void,
        label: String
    ) -> ToastMessage {
        do {
            try action(items)
            return ToastMessage(text: "Opening \(label)…")
        } catch {
            Log.shelf.error("\(label, privacy: .public) failed: \(error.localizedDescription, privacy: .public)")
            return ToastMessage(text: "Couldn't open \(label)")
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
            lastInsertedIDs = try shelfService.add(items)
            return ToastMessage(
                text: "Added \(lastInsertedIDs.count) to Shelf",
                isUndoable: !lastInsertedIDs.isEmpty
            )
        } catch {
            lastInsertedIDs = []
            Log.shelf.error("Failed to add to Shelf: \(error.localizedDescription, privacy: .public)")
            return ToastMessage(text: "Couldn't add to Shelf")
        }
    }
}
