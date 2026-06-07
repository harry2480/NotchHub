/// Settings persistence boundary used by the UI layer.
final class SettingsService {
    private let repository: SettingsRepository

    init(repository: SettingsRepository) {
        self.repository = repository
    }

    func load() throws -> AppSettings {
        try repository.load()
    }

    func save(_ settings: AppSettings) throws {
        try repository.save(settings)
    }
}
