import Foundation
@testable import NotchHub
import Testing

struct SQLiteSettingsRepositoryTests {
    private func makeRepository() throws -> SQLiteSettingsRepository {
        let database = try SQLiteDatabase.inMemory()
        try MigrationRunner(migrations: AppMigrations.settings).migrate(database)
        return SQLiteSettingsRepository(database: database)
    }

    @Test
    func loadReturnsDefaultsWhenEmpty() throws {
        let settings = try makeRepository().load()
        #expect(settings == AppSettings.default)
    }

    @Test
    func savesAndLoadsRoundTrip() throws {
        let repo = try makeRepository()
        var settings = AppSettings.default
        settings.lifespan = .days(30)
        settings.airDropPostSend = .delete
        settings.screenshotAutoImport = false
        settings.initialTab = .ai
        settings.showCalendar = false
        try repo.save(settings)

        #expect(try repo.load() == settings)
    }

    @Test
    func lifespanStorageRoundTrips() {
        #expect(ShelfLifespan(storageValue: ShelfLifespan.forever.storageValue) == .forever)
        #expect(ShelfLifespan(storageValue: ShelfLifespan.days(7).storageValue) == .days(7))
        #expect(ShelfLifespan(storageValue: "garbage") == .forever)
    }
}
