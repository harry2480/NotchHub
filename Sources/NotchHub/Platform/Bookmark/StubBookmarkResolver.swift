import Foundation

/// In-memory ``BookmarkResolving`` for tests/previews. Bookmarks are opaque
/// tokens mapped back to URLs; a URL can be marked "missing" to simulate the
/// original file having been deleted (so resolution throws).
final class StubBookmarkResolver: BookmarkResolving {
    enum StubError: Error, Equatable {
        case missing
    }

    private var urlsByToken: [Data: URL] = [:]
    private var missing: Set<URL> = []
    private var counter = 0

    func bookmark(for url: URL) throws -> Data {
        counter += 1
        let token = Data("bookmark-\(counter)".utf8)
        urlsByToken[token] = url
        return token
    }

    func resolve(_ data: Data) throws -> ResolvedBookmark {
        guard let url = urlsByToken[data], !missing.contains(url) else {
            throw StubError.missing
        }
        return ResolvedBookmark(url: url, isStale: false)
    }

    /// Simulates the original file being deleted.
    func markMissing(_ url: URL) {
        missing.insert(url)
    }
}
