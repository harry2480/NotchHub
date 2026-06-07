import Observation

/// Holds the live ``AppSettings`` and persists every change (要件定義.md §20).
/// Injected from the Composition Root so all features share one instance.
@MainActor
@Observable
final class SettingsStore {
    var settings: AppSettings {
        didSet { persist() }
    }

    private let repository: SettingsRepository

    init(repository: SettingsRepository) {
        self.repository = repository
        // `didSet` does not fire during init, so loading does not re-persist.
        settings = (try? repository.load()) ?? .default
    }

    private func persist() {
        do {
            try repository.save(settings)
        } catch {
            Log.app.error("Failed to save settings: \(error.localizedDescription, privacy: .public)")
        }
    }
}
