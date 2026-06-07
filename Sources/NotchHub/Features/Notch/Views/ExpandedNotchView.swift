import SwiftUI

/// The expanded notch content: the tab bar (Shelf | Calendar | Media | AI) and
/// the selected tab's body (要件定義.md §12). Tab bodies are placeholders until
/// their features land in later phases. Tab selection is local UI state for now;
/// the configurable initial tab arrives with Settings (Phase 4).
struct ExpandedNotchView: View {
    @State private var selectedTab: NotchTab = .shelf

    var body: some View {
        VStack(spacing: 0) {
            tabBar
            Divider()
            placeholder
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: NotchStyle.cornerRadius, style: .continuous))
    }

    private var tabBar: some View {
        HStack(spacing: 0) {
            ForEach(NotchTab.allCases) { tab in
                Button {
                    selectedTab = tab
                } label: {
                    Text(tab.title)
                        .font(.subheadline.weight(selectedTab == tab ? .semibold : .regular))
                        .foregroundStyle(selectedTab == tab ? Color.accentColor : Color.primary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                }
                .buttonStyle(.plain)
                .accessibilityAddTraits(selectedTab == tab ? [.isSelected] : [])
            }
        }
        .padding(.horizontal, NotchStyle.contentPadding)
    }

    private var placeholder: some View {
        VStack(spacing: 6) {
            Image(systemName: "shippingbox")
                .font(.system(size: 28))
                .foregroundStyle(.secondary)
            Text("\(selectedTab.title) coming soon")
                .font(.callout)
                .foregroundStyle(.secondary)
        }
    }
}
