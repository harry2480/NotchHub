import Foundation
@testable import NotchHub
import Testing

struct DefaultDropCoordinatorTests {
    private func makeCoordinator() -> (DefaultDropCoordinator, StubShelfRepository) {
        let repo = StubShelfRepository()
        let resolver = StubBookmarkResolver()
        let service = ShelfService(
            repository: repo,
            bookmarkResolver: resolver,
            workspace: StubWorkspaceOpener()
        )
        let factory = ShelfItemFactory(bookmarkResolver: resolver) { Date(timeIntervalSince1970: 1_000_000) }
        return (DefaultDropCoordinator(shelfService: service, itemFactory: factory), repo)
    }

    @Test
    func shelfDropPersistsItemsAndIsUndoable() throws {
        let (coordinator, repo) = makeCoordinator()
        let toast = coordinator.handle(DropRequest(zone: .shelf, items: [.text("hello"), .text("world")]))
        #expect(toast.isUndoable)
        #expect(toast.text == "Added 2 to Shelf")
        #expect(try repo.fetchAll().count == 2)
    }

    @Test
    func undoRemovesLastShelfDrop() throws {
        let (coordinator, repo) = makeCoordinator()
        let request = DropRequest(zone: .shelf, items: [.text("hello")])
        _ = coordinator.handle(request)
        #expect(try repo.fetchAll().count == 1)

        coordinator.undo(request)
        #expect(try repo.fetchAll().isEmpty)
    }

    @Test
    func shareAndAirDropAreNotUndoable() {
        let (coordinator, _) = makeCoordinator()
        #expect(!coordinator.handle(DropRequest(zone: .share, items: [.text("x")])).isUndoable)
        #expect(!coordinator.handle(DropRequest(zone: .airDrop, items: [.text("x")])).isUndoable)
    }
}
