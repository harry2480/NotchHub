import Foundation
@testable import NotchHub
import Testing

struct DefaultDropCoordinatorTests {
    private struct Harness {
        let coordinator: DefaultDropCoordinator
        let shelfRepo: StubShelfRepository
        let presenter: StubSharingPresenter
        let history: StubAirDropHistoryRepository
    }

    private func makeHarness() -> Harness {
        let shelfRepo = StubShelfRepository()
        let resolver = StubBookmarkResolver()
        let shelfService = ShelfService(
            repository: shelfRepo,
            bookmarkResolver: resolver,
            workspace: StubWorkspaceOpener()
        )
        let presenter = StubSharingPresenter()
        let history = StubAirDropHistoryRepository()
        let shareService = ShareService(
            sharing: presenter,
            tempFileWriter: StubTempFileWriter(),
            history: history
        )
        let factory = ShelfItemFactory(bookmarkResolver: resolver) { Date(timeIntervalSince1970: 1_000_000) }
        let coordinator = DefaultDropCoordinator(
            shelfService: shelfService,
            shareService: shareService,
            itemFactory: factory
        )
        return Harness(coordinator: coordinator, shelfRepo: shelfRepo, presenter: presenter, history: history)
    }

    @Test
    func shelfDropPersistsItemsAndIsUndoable() throws {
        let harness = makeHarness()
        let toast = harness.coordinator.handle(DropRequest(zone: .shelf, items: [.text("hello"), .text("world")]))
        #expect(toast.isUndoable)
        #expect(toast.text == "Added 2 to Shelf")
        #expect(try harness.shelfRepo.fetchAll().count == 2)
    }

    @Test
    func undoRemovesLastShelfDrop() throws {
        let harness = makeHarness()
        let request = DropRequest(zone: .shelf, items: [.text("hello")])
        _ = harness.coordinator.handle(request)
        #expect(try harness.shelfRepo.fetchAll().count == 1)
        harness.coordinator.undo(request)
        #expect(try harness.shelfRepo.fetchAll().isEmpty)
    }

    @Test
    func shareZonePresentsShareSheet() {
        let harness = makeHarness()
        let toast = harness.coordinator.handle(DropRequest(zone: .share, items: [.text("x")]))
        #expect(!toast.isUndoable)
        #expect(harness.presenter.sharedURLs.count == 1)
    }

    @Test
    func airDropZonePresentsAndRecordsHistory() throws {
        let harness = makeHarness()
        _ = harness.coordinator.handle(DropRequest(
            zone: .airDrop,
            items: [.fileURL(URL(fileURLWithPath: "/tmp/a.pdf"))]
        ))
        #expect(harness.presenter.airDroppedURLs.count == 1)
        let records = try harness.history.fetchAll()
        #expect(records.count == 1)
        #expect(records.first?.outcome == .sent)
        #expect(records.first?.originalPath == "/tmp/a.pdf")
    }
}
