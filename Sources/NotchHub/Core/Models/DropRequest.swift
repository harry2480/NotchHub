import Foundation

/// A single item being dragged onto the notch. Files are held by URL (the Shelf
/// later converts them to security-scoped bookmarks); text/URLs come from the
/// pasteboard inline.
enum DroppedItem: Equatable {
    case fileURL(URL)
    case text(String)
    case url(URL)
}

/// A completed drop: the chosen zone plus the items. Built only on `Drop`
/// (要件定義.md §7.4 "Drop 時のみ実行"); hovering never produces one.
struct DropRequest: Equatable {
    let zone: DropZone
    let items: [DroppedItem]
}
