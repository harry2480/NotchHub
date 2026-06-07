import Foundation

/// Imports a detected screenshot into the Shelf (要件定義.md §9). Honours the
/// ON/OFF setting and returns the created item (so the caller can toast).
final class ScreenshotImportService {
    private let shelfService: ShelfService
    private let bookmarkResolver: BookmarkResolving
    private let isEnabled: () -> Bool
    private let now: () -> Date

    init(
        shelfService: ShelfService,
        bookmarkResolver: BookmarkResolving,
        isEnabled: @escaping () -> Bool = { true },
        now: @escaping () -> Date = Date.init
    ) {
        self.shelfService = shelfService
        self.bookmarkResolver = bookmarkResolver
        self.isEnabled = isEnabled
        self.now = now
    }

    @discardableResult
    func importScreenshot(at url: URL) -> ShelfItem? {
        guard isEnabled() else { return nil }
        do {
            let bookmark = try bookmarkResolver.bookmark(for: url)
            let item = try ShelfItem.file(
                kind: .screenshot,
                name: url.lastPathComponent,
                bookmark: bookmark,
                originalPath: url.path,
                createdAt: now()
            )
            try shelfService.add(item)
            return item
        } catch {
            Log.shelf.error("Screenshot import failed: \(error.localizedDescription, privacy: .public)")
            return nil
        }
    }
}
