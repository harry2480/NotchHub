import Foundation

/// Drives Share Sheet and AirDrop for dropped items (要件定義.md §10, §11).
///
/// File items are shared directly; inline text / URLs are first materialised to
/// temp files (.txt / .webloc — 要件定義.md §8.5). AirDrop outcomes are written
/// to history, **without the recipient** (要件定義.md §10.5).
final class ShareService {
    private struct Resolved {
        let url: URL
        let name: String
        let kind: ShelfItemKind
        let originalPath: String?
    }

    private let sharing: SharingPresenting
    private let tempFileWriter: TempFileWriting
    private let history: AirDropHistoryRepository
    private let now: () -> Date

    init(
        sharing: SharingPresenting,
        tempFileWriter: TempFileWriting,
        history: AirDropHistoryRepository,
        now: @escaping () -> Date = Date.init
    ) {
        self.sharing = sharing
        self.tempFileWriter = tempFileWriter
        self.history = history
        self.now = now
    }

    /// Opens the macOS Share Sheet for the items (要件定義.md §11).
    func share(_ items: [DroppedItem]) throws {
        let resolved = try items.map(resolve(_:))
        sharing.presentShareSheet(for: resolved.map(\.url))
    }

    /// Sends the items via AirDrop and records the outcome in history
    /// (要件定義.md §10). Returns nothing; history is written on completion.
    func airDrop(_ items: [DroppedItem]) throws {
        let resolved = try items.map(resolve(_:))
        sharing.presentAirDrop(for: resolved.map(\.url)) { [weak self] outcome in
            self?.record(resolved, outcome: outcome)
        }
    }

    // MARK: - Private

    private func resolve(_ item: DroppedItem) throws -> Resolved {
        switch item {
        case let .fileURL(url):
            return Resolved(
                url: url,
                name: url.lastPathComponent,
                kind: ShelfItemFactory.fileKind(for: url),
                originalPath: url.path
            )
        case let .url(url):
            let name = url.host ?? "link"
            let file = try tempFileWriter.writeWebloc(url, suggestedName: name)
            return Resolved(url: file, name: name, kind: .url, originalPath: nil)
        case let .text(text):
            let name = ShelfItemFactory.title(forText: text)
            let file = try tempFileWriter.writeText(text, suggestedName: name)
            return Resolved(url: file, name: name, kind: .text, originalPath: nil)
        }
    }

    private func record(_ resolved: [Resolved], outcome: ShareOutcome) {
        let timestamp = now()
        for item in resolved {
            let record = AirDropRecord(
                name: item.name,
                kind: item.kind,
                date: timestamp,
                originalPath: item.originalPath,
                outcome: outcome
            )
            try? history.insert(record)
        }
    }
}
