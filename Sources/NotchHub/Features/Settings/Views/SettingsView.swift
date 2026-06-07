import SwiftUI

/// The Settings window content (要件定義.md §20). Edits write straight to the
/// shared ``SettingsStore``, which persists each change.
struct SettingsView: View {
    @Bindable var store: SettingsStore

    var body: some View {
        Form {
            Section("Shelf") {
                Picker("Lifespan", selection: $store.settings.lifespan) {
                    Text("Forever").tag(ShelfLifespan.forever)
                    Text("7 days").tag(ShelfLifespan.days(7))
                    Text("30 days").tag(ShelfLifespan.days(30))
                }
            }

            Section("AirDrop") {
                Picker("After sending", selection: $store.settings.airDropPostSend) {
                    Text("Keep in Shelf").tag(AirDropPostSendAction.keep)
                    Text("Delete").tag(AirDropPostSendAction.delete)
                }
            }

            Section("Screenshots") {
                Toggle("Add screenshots to Shelf", isOn: $store.settings.screenshotAutoImport)
            }

            Section("Notch") {
                Picker("Initial tab", selection: $store.settings.initialTab) {
                    ForEach(NotchTab.allCases) { tab in
                        Text(tab.title).tag(tab)
                    }
                }
                Toggle("Use pseudo-notch", isOn: $store.settings.pseudoNotchEnabled)
            }

            Section("Tabs") {
                Toggle("Show Calendar", isOn: $store.settings.showCalendar)
                Toggle("Show Media", isOn: $store.settings.showMedia)
                Toggle("Show AI", isOn: $store.settings.showAI)
            }
        }
        .formStyle(.grouped)
        .frame(width: 380, height: 420)
    }
}
