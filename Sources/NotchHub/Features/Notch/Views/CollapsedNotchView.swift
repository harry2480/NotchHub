import SwiftUI

/// The assimilated notch. Shows nothing by default, or a single glyph for the
/// highest-priority ``MinimalStatus`` (要件定義.md §6).
struct CollapsedNotchView: View {
    let status: MinimalStatus?

    var body: some View {
        ZStack {
            Capsule(style: .continuous)
                .fill(NotchStyle.notchFill)

            if let status {
                Text(status.glyph)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(.white)
                    .accessibilityLabel(accessibilityLabel(for: status))
            }
        }
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
