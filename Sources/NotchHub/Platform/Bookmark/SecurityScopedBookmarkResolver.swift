import Foundation

/// Production ``BookmarkResolving`` using security-scoped bookmarks
/// (リポジトリ層設計規約.md §ファイル参照保持). Callers must balance
/// `startAccessingSecurityScopedResource()` / `stop…` around actual file access.
final class SecurityScopedBookmarkResolver: BookmarkResolving {
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
        let accessed = url.startAccessingSecurityScopedResource()
        defer {
            if accessed {
                url.stopAccessingSecurityScopedResource()
            }
        }
        do {
            guard try url.checkResourceIsReachable() else {
                throw BookmarkError.fileMissing
            }
        } catch let error as BookmarkError {
            throw error
        } catch {
            let nsError = error as NSError
            if nsError.domain == NSCocoaErrorDomain, nsError.code == NSFileNoSuchFileError {
                throw BookmarkError.fileMissing
            }
            throw error
        }
        return ResolvedBookmark(url: url, isStale: isStale)
    }
}
