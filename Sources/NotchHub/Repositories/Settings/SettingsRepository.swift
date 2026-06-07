/// Persistence for ``AppSettings`` (要件定義.md §20). Missing keys fall back to
/// ``AppSettings/default``.
protocol SettingsRepository {
    func load() throws -> AppSettings
    func save(_ settings: AppSettings) throws
}
