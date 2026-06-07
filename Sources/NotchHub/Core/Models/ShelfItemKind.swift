/// The kind of thing held on the Shelf (要件定義.md §8.2).
///
/// File-like kinds are held by security-scoped bookmark; text-like kinds store
/// their content inline in SQLite (要件定義.md §8.3, §8.5).
enum ShelfItemKind: String, CaseIterable, Equatable {
    case file
    case folder
    case text
    case url
    case markdown
    case image
    case screenshot

    /// Whether this kind is backed by a file reference (bookmark) rather than
    /// inline text.
    var isFileBacked: Bool {
        switch self {
        case .file, .folder, .image, .screenshot: true
        case .text, .url, .markdown: false
        }
    }
}
