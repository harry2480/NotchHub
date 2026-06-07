import SwiftUI

/// The notch while a drag is in progress: the three drop zones, with the one
/// under the cursor highlighted (要件定義.md §7.2).
struct DraggingNotchView: View {
    let hoveredZone: DropZone?

    var body: some View {
        HStack(spacing: NotchStyle.zoneSpacing) {
            ForEach(DropZone.allCases, id: \.self) { zone in
                DropZoneView(zone: zone, isHighlighted: zone == hoveredZone)
            }
        }
        .padding(NotchStyle.contentPadding)
        .background(
            RoundedRectangle(cornerRadius: NotchStyle.cornerRadius, style: .continuous)
                .fill(NotchStyle.notchFill.opacity(0.92))
        )
    }
}
