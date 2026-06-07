/// In-memory ``SettingsRepository`` for tests/previews.
final class StubSettingsRepository: SettingsRepository {
    private(set) var stored: AppSettings

    init(settings: AppSettings = .default) {
        stored = settings
    }

    func load() throws -> AppSettings {
        stored
    }

    func save(_ settings: AppSettings) throws {
        stored = settings
    }
}
