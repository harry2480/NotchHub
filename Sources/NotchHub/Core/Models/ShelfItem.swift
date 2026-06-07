import Foundation

/// A single Shelf entry (要件定義.md §8). A Rich Domain Model: construction
/// enforces the invariants for each kind (file-backed kinds need a bookmark;
/// text-backed kinds need a body), so an invalid item cannot exist.
struct ShelfItem: Identifiable, Equatable {
    enum ValidationError: Error, Equatable {
        case emptyName
        case missingBody
        case missingBookmark
        case missingURL
    }

    let id: UUID
    let kind: ShelfItemKind
    var name: String
    let createdAt: Date
    var isPinned: Bool
    /// Inline content for `.text` / `.markdown`.
    var body: String?
    /// Source URL string for `.url`, or the original path for file-backed kinds.
    var urlString: String?
    /// Security-scoped bookmark for file-backed kinds.
    var bookmark: Data?

    init(
        id: UUID = UUID(),
        kind: ShelfItemKind,
        name: String,
        createdAt: Date,
        isPinned: Bool = false,
        body: String? = nil,
        urlString: String? = nil,
        bookmark: Data? = nil
    ) throws {
        guard !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw ValidationError.emptyName
        }
        switch kind {
        case .text, .markdown:
            guard let body, !body.isEmpty else { throw ValidationError.missingBody }
        case .url:
            guard urlString != nil else { throw ValidationError.missingURL }
        case .file, .folder, .image, .screenshot:
            guard bookmark != nil else { throw ValidationError.missingBookmark }
        }
        self.id = id
        self.kind = kind
        self.name = name
        self.createdAt = createdAt
        self.isPinned = isPinned
        self.body = body
        self.urlString = urlString
        self.bookmark = bookmark
    }

    // MARK: - Factories

    static func text(
        id: UUID = UUID(),
        name: String,
        body: String,
        createdAt: Date,
        isPinned: Bool = false,
        markdown: Bool = false
    ) throws -> ShelfItem {
        try ShelfItem(
            id: id,
            kind: markdown ? .markdown : .text,
            name: name,
            createdAt: createdAt,
            isPinned: isPinned,
            body: body
        )
    }

    static func url(
        id: UUID = UUID(),
        name: String,
        url: URL,
        createdAt: Date,
        isPinned: Bool = false
    ) throws -> ShelfItem {
        try ShelfItem(
            id: id,
            kind: .url,
            name: name,
            createdAt: createdAt,
            isPinned: isPinned,
            urlString: url.absoluteString
        )
    }

    static func file(
        id: UUID = UUID(),
        kind: ShelfItemKind = .file,
        name: String,
        bookmark: Data,
        originalPath: String? = nil,
        createdAt: Date,
        isPinned: Bool = false
    ) throws -> ShelfItem {
        try ShelfItem(
            id: id,
            kind: kind,
            name: name,
            createdAt: createdAt,
            isPinned: isPinned,
            urlString: originalPath,
            bookmark: bookmark
        )
    }

    /// Text used for full-text search (要件定義.md §8.12): name + URL + body.
    var searchableText: String {
        [name, urlString, body].compactMap { $0 }.joined(separator: " ")
    }
}
