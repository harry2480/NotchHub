import SwiftUI

/// A transient toast with an optional Undo button (要件定義.md §7.4).
struct ToastView: View {
    let message: ToastMessage
    var onUndo: (() -> Void)?

    var body: some View {
        HStack(spacing: 10) {
            Text(message.text)
                .font(.callout)
                .foregroundStyle(.primary)

            if message.isUndoable, let onUndo {
                Button("Undo", action: onUndo)
                    .buttonStyle(.borderless)
                    .font(.callout.weight(.semibold))
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 8)
        .background(.regularMaterial, in: Capsule())
        .overlay(Capsule().strokeBorder(.separator))
    }
}
