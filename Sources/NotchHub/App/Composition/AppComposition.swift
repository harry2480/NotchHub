import AppKit

/// Composition Root — the single place where concrete implementations are wired
/// to their protocols (アーキテクチャ.md). No other layer constructs adapters or
/// repositories directly.
///
/// `bootstrap()` opens the databases and builds the repositories; the factory
/// methods assemble the services, view models and windows on the main actor.
final class AppComposition {
    let loginItemManager: LoginItemManaging

    private let bookmarkResolver: BookmarkResolving = SecurityScopedBookmarkResolver()
    private let workspace: WorkspaceOpening = AppKitWorkspaceOpener()

    // Repositories retain their database connections.
    private(set) var shelfRepository: ShelfRepository?
    private(set) var airDropHistoryRepository: AirDropHistoryRepository?
    private(set) var settingsRepository: SettingsRepository?

    private(set) var settingsStore: SettingsStore?
    private var aiMonitorService: AIMonitorService?

    init(loginItemManager: LoginItemManaging = SMAppServiceLoginItemManager()) {
        self.loginItemManager = loginItemManager
    }

    /// Opens databases and applies migrations. Call once at launch.
    func bootstrap() throws {
        let shelfDatabase = try SQLiteDatabase(path: AppPaths.databaseURL(named: "shelf.db").path)
        try MigrationRunner(migrations: AppMigrations.shelf).migrate(shelfDatabase)
        shelfRepository = SQLiteShelfRepository(database: shelfDatabase)

        let historyDatabase = try SQLiteDatabase(path: AppPaths.databaseURL(named: "airdrop_history.db").path)
        try MigrationRunner(migrations: AppMigrations.airDropHistory).migrate(historyDatabase)
        airDropHistoryRepository = SQLiteAirDropHistoryRepository(database: historyDatabase)

        let settingsDatabase = try SQLiteDatabase(path: AppPaths.databaseURL(named: "settings.db").path)
        try MigrationRunner(migrations: AppMigrations.settings).migrate(settingsDatabase)
        settingsRepository = SQLiteSettingsRepository(database: settingsDatabase)

        Log.app.info("Composition bootstrap complete")
    }

    /// Assembles the notch window, its services and view models.
    @MainActor
    func makeNotchController() -> NotchWindowController {
        let settingsStore = SettingsStore(repository: settingsRepository ?? StubSettingsRepository())
        self.settingsStore = settingsStore

        let shelfService = ShelfService(
            repository: shelfRepository ?? StubShelfRepository(),
            bookmarkResolver: bookmarkResolver,
            workspace: workspace,
            lifespan: settingsStore.settings.lifespan
        )
        let shareService = ShareService(
            sharing: AppKitSharingPresenter(anchor: { NSApp.windows.first { $0 is NSPanel }?.contentView }),
            tempFileWriter: makeTempFileWriter(),
            history: airDropHistoryRepository ?? StubAirDropHistoryRepository()
        )
        let dropCoordinator = DefaultDropCoordinator(
            shelfService: shelfService,
            shareService: shareService,
            itemFactory: ShelfItemFactory(bookmarkResolver: bookmarkResolver)
        )

        let screenProvider = AppKitScreenProvider()
        let notchViewModel = NotchViewModel(screenProvider: screenProvider, dropCoordinator: dropCoordinator)

        let aiService = AIMonitorService(socket: makeAISocketServer())
        aiService.onApprovalNeeded = { [weak notchViewModel] _ in
            MainActor.assumeIsolated { notchViewModel?.aiApprovalRequested() }
        }
        aiService.start()
        aiMonitorService = aiService

        let scene = NotchScene(
            notch: notchViewModel,
            shelf: ShelfViewModel(service: shelfService),
            calendar: CalendarViewModel(
                service: CalendarService(provider: EventKitCalendarProvider()),
                workspace: workspace
            ),
            media: MediaViewModel(controller: AppleScriptMediaController()),
            ai: AIMonitorViewModel(service: aiService, workspace: workspace),
            settings: settingsStore
        )

        let screenshotImporter = ScreenshotImportService(
            shelfService: shelfService,
            bookmarkResolver: bookmarkResolver,
            isEnabled: { [weak settingsStore] in settingsStore?.settings.screenshotAutoImport ?? true }
        )

        return NotchWindowController(
            scene: scene,
            screenProvider: screenProvider,
            dragMonitor: AppKitGlobalDragMonitor(),
            screenshotMonitor: DirectoryScreenshotMonitor(),
            screenshotImporter: screenshotImporter
        )
    }

    /// Settings window, sharing the same ``SettingsStore`` as the notch.
    @MainActor
    func makeSettingsWindowController() -> SettingsWindowController {
        let store = settingsStore ?? SettingsStore(repository: settingsRepository ?? StubSettingsRepository())
        settingsStore = store
        return SettingsWindowController(store: store)
    }

    private func makeTempFileWriter() -> TempFileWriting {
        (try? CacheTempFileWriter.standard()) ?? CacheTempFileWriter(directory: FileManager.default.temporaryDirectory)
    }

    private func makeAISocketServer() -> AISocketServing {
        (try? UnixSocketAIServer.standard()) ?? StubAISocketServer()
    }
}
