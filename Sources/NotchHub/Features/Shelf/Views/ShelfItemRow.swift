import SwiftUI

/// One Shelf row: icon, name, pin/delete actions (要件定義.md §8.8, §8.11).
struct ShelfItemRow: View {
    let item: ShelfItem
    let onOpen: () -> Void
    let onTogglePin: () -> Void
    let onReveal: () -> Void
    let onDelete: () -> Void

    var body: some View {
        Button(action: onOpen) {
            HStack(spacing: 8) {
                Image(systemName: symbolName)
                    .frame(width: 18)
                    .foregroundStyle(.secondary)
                Text(item.name)
                    .lineLimit(1)
                    .truncationMode(.middle)
                Spacer(minLength: 8)
                if item.isPinned {
                    Image(systemName: "pin.fill")
                        .font(.caption2)
                        .foregroundStyle(.orange)
                }
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .contextMenu {
            Button("Open", action: onOpen)
            if item.kind.isFileBacked {
                Button("Reveal in Finder", action: onReveal)
            }
            Button(item.isPinned ? "Unpin" : "Pin", action: onTogglePin)
            Divider()
            Button("Delete", role: .destructive, action: onDelete)
        }
    }

    private var symbolName: String {
        switch item.kind {
        case .file: "doc"
        case .folder: "folder"
        case .text: "note.text"
        case .url: "link"
        case .markdown: "doc.richtext"
        case .image, .screenshot: "photo"
        }
    }
}
