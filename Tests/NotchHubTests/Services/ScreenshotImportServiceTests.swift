import Foundation
@testable import NotchHub
import Testing

struct ScreenshotImportServiceTests {
    private func makeService(enabled: Bool) -> (ScreenshotImportService, StubShelfRepository) {
        let repo = StubShelfRepository()
        let shelfService = ShelfService(
            repository: repo,
            bookmarkResolver: StubBookmarkResolver(),
            workspace: StubWorkspaceOpener()
        )
        let service = ScreenshotImportService(
            shelfService: shelfService,
            bookmarkResolver: StubBookmarkResolver(),
            isEnabled: { enabled },
            now: { Date(timeIntervalSince1970: 1_000_000) }
        )
        return (service, repo)
    }

    @Test
    func importsScreenshotWhenEnabled() throws {
        let (service, repo) = makeService(enabled: true)
        let item = service.importScreenshot(at: URL(fileURLWithPath: "/tmp/Screenshot.png"))
        #expect(item?.kind == .screenshot)
        #expect(try repo.fetchAll().count == 1)
    }

    @Test
    func skipsWhenDisabled() throws {
        let (service, repo) = makeService(enabled: false)
        #expect(service.importScreenshot(at: URL(fileURLWithPath: "/tmp/Screenshot.png")) == nil)
        #expect(try repo.fetchAll().isEmpty)
    }
}
