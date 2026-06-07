import Foundation

/// A resolved security-scoped bookmark.
struct ResolvedBookmark: Equatable {
    let url: URL
    /// True when the bookmark resolved but is stale and should be recreated.
    let isStale: Bool
}

/// Creates and resolves security-scoped bookmarks, hiding the file-system /
/// sandbox APIs behind a protocol (AGENTS.md 永続化規約・リポジトリ層設計規約.md).
/// Resolution throws when the original file no longer exists, which the Shelf
/// uses to auto-remove dangling items.
protocol BookmarkResolving {
    func bookmark(for url: URL) throws -> Data
    func resolve(_ data: Data) throws -> ResolvedBookmark
}
