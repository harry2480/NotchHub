import SwiftUI

/// The expanded notch content: the tab bar (Shelf | Calendar | Media | AI) and
/// the selected tab's body (要件定義.md §12). Visible tabs and the initial tab
/// come from Settings (要件定義.md §20).
struct ExpandedNotchView: View {
    let scene: NotchScene
    @State private var selectedTab: NotchTab

    init(scene: NotchScene) {
        self.scene = scene
        let settings = scene.settings.settings
        let initial = Self.isVisible(settings.initialTab, settings: settings) ? settings.initialTab : .shelf
        _selectedTab = State(initialValue: initial)
    }

    var body: some View {
        VStack(spacing: 0) {
            tabBar
            Divider()
            content
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: NotchStyle.cornerRadius, style: .continuous))
        .onChange(of: visibleTabs) { _, tabs in
            if !tabs.contains(selectedTab) {
                selectedTab = tabs.first ?? .shelf
            }
        }
    }

    private var visibleTabs: [NotchTab] {
        let settings = scene.settings.settings
        return NotchTab.allCases.filter { Self.isVisible($0, settings: settings) }
    }

    private static func isVisible(_ tab: NotchTab, settings: AppSettings) -> Bool {
        switch tab {
        case .shelf: true
        case .calendar: settings.showCalendar
        case .media: settings.showMedia
        case .ai: settings.showAI
        }
    }

    @ViewBuilder
    private var content: some View {
        switch selectedTab {
        case .shelf:
            ShelfListView(viewModel: scene.shelf)
        case .calendar:
            CalendarView(viewModel: scene.calendar)
        case .media:
            MediaControlView(viewModel: scene.media)
        case .ai:
            AISessionListView(viewModel: scene.ai)
        }
    }

    private var tabBar: some View {
        HStack(spacing: 0) {
            ForEach(visibleTabs) { tab in
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
}
