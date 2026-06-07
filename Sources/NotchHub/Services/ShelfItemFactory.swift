import Foundation

/// Builds ``ShelfItem``s from dropped items (要件定義.md §8.2). File URLs become
/// bookmark-backed items; text/URLs are stored inline. Kept separate from the
/// coordinator so the conversion rules can be unit-tested.
struct ShelfItemFactory {
    private let bookmarkResolver: BookmarkResolving
    private let now: () -> Date

    init(bookmarkResolver: BookmarkResolving, now: @escaping () -> Date = Date.init) {
        self.bookmarkResolver = bookmarkResolver
        self.now = now
    }

    func makeItems(from dropped: [DroppedItem]) throws -> [ShelfItem] {
        try dropped.map(makeItem(from:))
    }

    func makeItem(from dropped: DroppedItem) throws -> ShelfItem {
        let timestamp = now()
        switch dropped {
        case let .fileURL(url):
            let bookmark = try bookmarkResolver.bookmark(for: url)
            return try ShelfItem.file(
                kind: Self.fileKind(for: url),
                name: url.lastPathComponent,
                bookmark: bookmark,
                originalPath: url.path,
                createdAt: timestamp
            )
        case let .url(url):
            return try ShelfItem.url(name: url.host ?? url.absoluteString, url: url, createdAt: timestamp)
        case let .text(text):
            return try ShelfItem.text(name: Self.title(forText: text), body: text, createdAt: timestamp)
        }
    }

    private static let imageExtensions: Set<String> = ["png", "jpg", "jpeg", "gif", "heic", "webp", "tiff", "bmp"]

    static func fileKind(for url: URL) -> ShelfItemKind {
        if url.hasDirectoryPath { return .folder }
        if imageExtensions.contains(url.pathExtension.lowercased()) { return .image }
        return .file
    }

    /// A short display name from text: its first non-empty line (after trimming),
    /// truncated.
    static func title(forText text: String) -> String {
        let firstLine = text
            .split(whereSeparator: \.isNewline)
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .first { !$0.isEmpty } ?? ""
        let candidate = firstLine.isEmpty ? "Untitled" : firstLine
        return candidate.count > 40 ? String(candidate.prefix(40)) + "…" : candidate
    }
}
