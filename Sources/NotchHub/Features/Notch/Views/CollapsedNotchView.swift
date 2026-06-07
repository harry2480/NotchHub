import SwiftUI

/// The assimilated notch. By default it renders nothing (so it blends with the
/// hardware notch / wallpaper) and only acts as a click target; when a
/// ``MinimalStatus`` is active it shows a single compact badge (要件定義.md §6).
struct CollapsedNotchView: View {
    let status: MinimalStatus?
    var onClick: () -> Void = {}

    var body: some View {
        ZStack {
            // Transparent base keeps the whole collapsed area clickable while
            // staying invisible when idle (要件定義.md §5.1 同化).
            Color.clear

            if let status {
                Text(status.glyph)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 3)
                    .background(Capsule(style: .continuous).fill(NotchStyle.notchFill))
                    .accessibilityLabel(accessibilityLabel(for: status))
            }
        }
        .contentShape(Rectangle())
        .onTapGesture(perform: onClick)
    }

    private func accessibilityLabel(for status: MinimalStatus) -> String {
        switch status {
        case .aiApprovalWaiting: "AI approval waiting"
        case .dragging: "Dragging"
        case .sharing: "Sharing"
        case .mediaPlaying: "Media playing"
        case .upcomingEvent: "Upcoming event"
        }
    }
}
