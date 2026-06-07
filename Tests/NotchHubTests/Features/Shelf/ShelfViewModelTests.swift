import Foundation
@testable import NotchHub
import Testing

@MainActor
struct ShelfViewModelTests {
    private let epoch = Date(timeIntervalSince1970: 1_000_000)

    private func makeViewModel(items: [ShelfItem] = []) -> (ShelfViewModel, StubShelfRepository) {
        let repo = StubShelfRepository(items: items)
        let service = ShelfService(
            repository: repo,
            bookmarkResolver: StubBookmarkResolver(),
            workspace: StubWorkspaceOpener()
        )
        return (ShelfViewModel(service: service), repo)
    }

    @Test
    func refreshLoadsOrderedItems() throws {
        let a = try ShelfItem.text(name: "a", body: "a", createdAt: epoch)
        let b = try ShelfItem.text(name: "b", body: "b", createdAt: epoch.addingTimeInterval(10))
        let (viewModel, _) = makeViewModel(items: [a, b])
        viewModel.refresh()
        #expect(viewModel.items.map(\.name) == ["b", "a"]) // newest first
    }

    @Test
    func searchFiltersItems() throws {
        let a = try ShelfItem.text(name: "apple", body: "x", createdAt: epoch)
        let b = try ShelfItem.text(name: "banana", body: "y", createdAt: epoch.addingTimeInterval(10))
        let (viewModel, _) = makeViewModel(items: [a, b])
        viewModel.searchText = "ban"
        viewModel.refresh()
        #expect(viewModel.items.map(\.name) == ["banana"])
    }

    @Test
    func togglePinUpdatesAndWarnsAtLimit() throws {
        let item = try ShelfItem.text(name: "memo", body: "x", createdAt: epoch)
        let pinned = try (0 ..< ShelfLimits.pinned).map {
            try ShelfItem.text(
                name: "p\($0)",
                body: "x",
                createdAt: epoch.addingTimeInterval(TimeInterval($0)),
                isPinned: true
            )
        }
        let (viewModel, _) = makeViewModel(items: pinned + [item])
        viewModel.togglePin(item)
        #expect(viewModel.warning != nil) // pinned limit reached
    }

    @Test
    func deleteAndDeleteAll() throws {
        let a = try ShelfItem.text(name: "a", body: "a", createdAt: epoch)
        let b = try ShelfItem.text(name: "b", body: "b", createdAt: epoch.addingTimeInterval(10))
        let (viewModel, _) = makeViewModel(items: [a, b])
        viewModel.refresh()
        viewModel.delete(a)
        #expect(viewModel.items.map(\.name) == ["b"])
        viewModel.deleteAll()
        #expect(viewModel.items.isEmpty)
    }
}
