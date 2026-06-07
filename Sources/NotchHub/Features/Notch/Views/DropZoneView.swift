import SwiftUI

/// A single drop zone cell (Shelf / Share / AirDrop). Highlights before drop to
/// signal where the item will go (要件定義.md §7.4 強調表示).
struct DropZoneView: View {
    let zone: DropZone
    let isHighlighted: Bool

    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: symbolName)
                .font(.system(size: 22, weight: .regular))
            Text(zone.title)
                .font(.headline)
            Text(zone.subtitle)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .foregroundStyle(isHighlighted ? Color.accentColor : Color.primary)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(
            RoundedRectangle(cornerRadius: NotchStyle.zoneCornerRadius, style: .continuous)
                .fill(isHighlighted ? Color.accentColor.opacity(0.22) : Color.secondary.opacity(0.10))
        )
        .overlay(
            RoundedRectangle(cornerRadius: NotchStyle.zoneCornerRadius, style: .continuous)
                .strokeBorder(Color.accentColor, lineWidth: isHighlighted ? 2 : 0)
        )
        .scaleEffect(isHighlighted ? 1.03 : 1)
        .animation(.easeOut(duration: 0.12), value: isHighlighted)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(zone.title), \(zone.subtitle)")
    }

    private var symbolName: String {
        switch zone {
        case .shelf: "tray.and.arrow.down.fill"
        case .share: "square.and.arrow.up"
        case .airDrop: "dot.radiowaves.right"
        }
    }
}
