import Foundation

/// Production ``BookmarkResolving`` using security-scoped bookmarks
/// (リポジトリ層設計規約.md §ファイル参照保持). Callers must balance
/// `startAccessingSecurityScopedResource()` / `stop…` around actual file access.
final class SecurityScopedBookmarkResolver: BookmarkResolving {
    enum BookmarkError: Error {
        case unresolvable
    }

    func bookmark(for url: URL) throws -> Data {
        try url.bookmarkData(
            options: [.withSecurityScope],
            includingResourceValuesForKeys: nil,
            relativeTo: nil
        )
    }

    func resolve(_ data: Data) throws -> ResolvedBookmark {
        var isStale = false
        let url = try URL(
            resolvingBookmarkData: data,
            options: [.withSecurityScope],
            relativeTo: nil,
            bookmarkDataIsStale: &isStale
        )
        return ResolvedBookmark(url: url, isStale: isStale)
    }
}
