import Observation

/// Holds the live ``AppSettings`` and persists every change (要件定義.md §20).
/// Injected from the Composition Root so all features share one instance.
@MainActor
@Observable
final class SettingsStore {
    var settings: AppSettings {
        didSet { persist() }
    }

    private let service: SettingsService

    init(service: SettingsService) throws {
        self.service = service
        settings = try service.load()
    }

    private func persist() {
        do {
            try service.save(settings)
        } catch {
            Log.app.error("Failed to save settings: \(error.localizedDescription, privacy: .public)")
        }
    }
}
