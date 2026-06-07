/// SQLite-backed ``SettingsRepository`` (`settings` key/value table in
/// `settings.db`). Each ``AppSettings`` field maps to a key; unknown/missing
/// keys fall back to the default.
final class SQLiteSettingsRepository: SettingsRepository {
    private let database: SQLiteDatabase

    init(database: SQLiteDatabase) {
        self.database = database
    }

    private enum Key {
        static let lifespan = "lifespan"
        static let airDropPostSend = "airdrop_post_send"
        static let screenshotAutoImport = "screenshot_auto_import"
        static let initialTab = "initial_tab"
        static let pseudoNotch = "pseudo_notch"
        static let showAI = "show_ai"
        static let showCalendar = "show_calendar"
        static let showMedia = "show_media"
    }

    func load() throws -> AppSettings {
        var values: [String: String] = [:]
        for row in try database.query("SELECT key, value FROM settings;") {
            if let key = row.string("key"), let value = row.string("value") {
                values[key] = value
            }
        }
        let fallback = AppSettings.default
        return AppSettings(
            lifespan: values[Key.lifespan].map(ShelfLifespan.init(storageValue:)) ?? fallback.lifespan,
            airDropPostSend: values[Key.airDropPostSend].map(AirDropPostSendAction.init(storageValue:))
                ?? fallback.airDropPostSend,
            screenshotAutoImport: boolValue(values[Key.screenshotAutoImport], fallback.screenshotAutoImport),
            initialTab: values[Key.initialTab].flatMap(NotchTab.init(rawValue:)) ?? fallback.initialTab,
            pseudoNotchEnabled: boolValue(values[Key.pseudoNotch], fallback.pseudoNotchEnabled),
            showAI: boolValue(values[Key.showAI], fallback.showAI),
            showCalendar: boolValue(values[Key.showCalendar], fallback.showCalendar),
            showMedia: boolValue(values[Key.showMedia], fallback.showMedia)
        )
    }

    func save(_ settings: AppSettings) throws {
        try database.transaction {
            try set(Key.lifespan, settings.lifespan.storageValue)
            try set(Key.airDropPostSend, settings.airDropPostSend.storageValue)
            try set(Key.screenshotAutoImport, boolString(settings.screenshotAutoImport))
            try set(Key.initialTab, settings.initialTab.rawValue)
            try set(Key.pseudoNotch, boolString(settings.pseudoNotchEnabled))
            try set(Key.showAI, boolString(settings.showAI))
            try set(Key.showCalendar, boolString(settings.showCalendar))
            try set(Key.showMedia, boolString(settings.showMedia))
        }
    }

    private func set(_ key: String, _ value: String) throws {
        try database.run(
            "INSERT OR REPLACE INTO settings (key, value) VALUES (?, ?);",
            [.text(key), .text(value)]
        )
    }

    private func boolValue(_ raw: String?, _ fallback: Bool) -> Bool {
        guard let raw else { return fallback }
        return raw == "1"
    }

    private func boolString(_ value: Bool) -> String {
        value ? "1" : "0"
    }
}
