@testable import NotchHub
import Testing

@MainActor
struct SettingsStoreTests {
    @Test
    func loadsInitialSettingsFromRepository() throws {
        var initial = AppSettings.default
        initial.screenshotAutoImport = false
        let store = try SettingsStore(
            service: SettingsService(repository: StubSettingsRepository(settings: initial))
        )
        #expect(store.settings.screenshotAutoImport == false)
    }

    @Test
    func mutatingSettingsPersists() throws {
        let repository = StubSettingsRepository()
        let store = try SettingsStore(service: SettingsService(repository: repository))
        store.settings.initialTab = .media
        #expect(repository.stored.initialTab == .media)
    }

    @Test
    func loadFailureIsNotSilentlyReplacedWithDefaults() {
        struct LoadFailure: Error {}

        final class FailingRepository: SettingsRepository {
            func load() throws -> AppSettings {
                throw LoadFailure()
            }

            func save(_: AppSettings) throws {}
        }

        #expect(throws: LoadFailure.self) {
            try SettingsStore(service: SettingsService(repository: FailingRepository()))
        }
    }
}
