import Foundation
@testable import NotchHub
import Testing

struct ShelfServiceTests {
    private let epoch = Date(timeIntervalSince1970: 1_000_000)

    private struct Harness {
        let service: ShelfService
        let repo: StubShelfRepository
        let workspace: StubWorkspaceOpener
    }

    private func makeHarness(
        items: [ShelfItem] = [],
        resolver: StubBookmarkResolver = StubBookmarkResolver(),
        lifespan: ShelfLifespan = .forever,
        now: @escaping () -> Date = { Date(timeIntervalSince1970: 2_000_000) }
    ) -> Harness {
        let repo = StubShelfRepository(items: items)
        let workspace = StubWorkspaceOpener()
        let service = ShelfService(
            repository: repo,
            bookmarkResolver: resolver,
            workspace: workspace,
            lifespan: lifespan,
            now: now
        )
        return Harness(service: service, repo: repo, workspace: workspace)
    }

    private func text(_ name: String, at offset: TimeInterval, pinned: Bool = false) throws -> ShelfItem {
        try ShelfItem.text(name: name, body: name, createdAt: epoch.addingTimeInterval(offset), isPinned: pinned)
    }

    @Test
    func addEvictsOldestUnpinnedAtLimit() throws {
        let existing = try (0 ..< ShelfLimits.regular).map { try text("item\($0)", at: TimeInterval($0)) }
        let harness = makeHarness(items: existing)

        try harness.service.add(text("new", at: 10000))

        let names = try harness.repo.fetchAll().map(\.name)
        #expect(names.contains("new"))
        #expect(!names.contains("item0")) // oldest unpinned evicted
        #expect(try harness.repo.fetchAll().count == ShelfLimits.regular)
    }

    @Test
    func addDoesNotEvictPinnedItems() throws {
        var existing = try (0 ..< ShelfLimits.regular).map { try text("item\($0)", at: TimeInterval($0)) }
        existing[0].isPinned = true // oldest is pinned
        let harness = makeHarness(items: existing)

        // 49 unpinned < limit, so nothing is evicted yet on this add.
        try harness.service.add(text("new1", at: 20000))
        #expect(try harness.repo.fetchAll().map(\.name).contains("item0"))
    }

    @Test
    func setPinnedRefusesBeyondPinnedLimit() throws {
        let pinned = try (0 ..< ShelfLimits.pinned).map { try text("p\($0)", at: TimeInterval($0), pinned: true) }
        let extra = try text("extra", at: 99999)
        let harness = makeHarness(items: pinned + [extra])

        #expect(try harness.service.setPinned(extra.id, true) == .limitReached)
    }

    @Test
    func rePinningAlreadyPinnedItemIsIdempotentAtLimit() throws {
        // All pinned slots full; re-pinning one that is already pinned must
        // succeed (idempotent), not hit the limit.
        let pinned = try (0 ..< ShelfLimits.pinned).map { try text("p\($0)", at: TimeInterval($0), pinned: true) }
        let harness = makeHarness(items: pinned)
        let target = try #require(pinned.first)
        #expect(try harness.service.setPinned(target.id, true) == .pinned)
    }

    @Test
    func sweepExpiredRemovesUnpinnedExpiredOnly() throws {
        let old = try text("old", at: 0) // created at epoch
        let pinnedOld = try text("pinnedOld", at: 0, pinned: true)
        let fresh = try text("fresh", at: 1_999_990) // 10s before "now" → not expired
        let now = { epoch.addingTimeInterval(2_000_000) }
        let harness = makeHarness(items: [old, pinnedOld, fresh], lifespan: .days(1), now: now)

        let removed = try harness.service.sweepExpired()
        let names = try harness.repo.fetchAll().map(\.name)
        #expect(removed == [old.id])
        #expect(names.contains("pinnedOld")) // pinned never expires
        #expect(names.contains("fresh"))
        #expect(!names.contains("old"))
    }

    @Test
    func pruneMissingFilesRemovesDanglingItems() throws {
        let resolver = StubBookmarkResolver()
        let presentURL = URL(fileURLWithPath: "/tmp/present.pdf")
        let missingURL = URL(fileURLWithPath: "/tmp/missing.pdf")
        let presentBookmark = try resolver.bookmark(for: presentURL)
        let missingBookmark = try resolver.bookmark(for: missingURL)
        resolver.markMissing(missingURL)

        let present = try ShelfItem.file(name: "present.pdf", bookmark: presentBookmark, createdAt: epoch)
        let missing = try ShelfItem.file(name: "missing.pdf", bookmark: missingBookmark, createdAt: epoch)
        let harness = makeHarness(items: [present, missing], resolver: resolver)

        let removed = try harness.service.pruneMissingFiles()
        #expect(removed == [missing.id])
        #expect(try harness.repo.fetchAll().map(\.name) == ["present.pdf"])
    }

    @Test
    func openResolvesAndDelegatesToWorkspace() throws {
        let resolver = StubBookmarkResolver()
        let url = URL(fileURLWithPath: "/tmp/doc.pdf")
        let bookmark = try resolver.bookmark(for: url)
        let item = try ShelfItem.file(name: "doc.pdf", bookmark: bookmark, createdAt: epoch)
        let harness = makeHarness(items: [item], resolver: resolver)

        try harness.service.open(item)
        try harness.service.revealInFinder(item)
        #expect(harness.workspace.opened == [url])
        #expect(harness.workspace.revealed == [url])
    }
}
