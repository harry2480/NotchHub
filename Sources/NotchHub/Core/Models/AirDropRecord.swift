import Foundation

/// A persisted AirDrop history entry (要件定義.md §10.5).
///
/// Stores name / kind / date / original path / result. The **recipient is
/// intentionally never stored** (要件定義.md §10.5 保存しない: 送信先).
struct AirDropRecord: Identifiable, Equatable {
    let id: UUID
    let name: String
    let kind: ShelfItemKind
    let date: Date
    /// Original file path when the source was a file; `nil` for inline text/URL.
    let originalPath: String?
    let outcome: ShareOutcome

    init(
        id: UUID = UUID(),
        name: String,
        kind: ShelfItemKind,
        date: Date,
        originalPath: String? = nil,
        outcome: ShareOutcome
    ) {
        self.id = id
        self.name = name
        self.kind = kind
        self.date = date
        self.originalPath = originalPath
        self.outcome = outcome
    }
}
