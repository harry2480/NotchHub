@testable import NotchHub
import Testing

@MainActor
struct SettingsStoreTests {
    @Test
    func loadsInitialSettingsFromRepository() {
        var initial = AppSettings.default
        initial.screenshotAutoImport = false
        let store = SettingsStore(repository: StubSettingsRepository(settings: initial))
        #expect(store.settings.screenshotAutoImport == false)
    }

    @Test
    func mutatingSettingsPersists() {
        let repository = StubSettingsRepository()
        let store = SettingsStore(repository: repository)
        store.settings.initialTab = .media
        #expect(repository.stored.initialTab == .media)
    }
}
