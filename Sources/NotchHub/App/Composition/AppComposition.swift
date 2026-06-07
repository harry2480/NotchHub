import AppKit

/// Composition Root — the single place where concrete implementations are wired
/// to their protocols (アーキテクチャ.md). No other layer constructs adapters or
/// repositories directly.
///
/// `bootstrap()` opens the databases and builds the Shelf / AirDrop-history
/// stacks; the factory method assembles the notch window and its view models.
final class AppComposition {
    let loginItemManager: LoginItemManaging

    private let bookmarkResolver: BookmarkResolving = SecurityScopedBookmarkResolver()
    private let workspace: WorkspaceOpening = AppKitWorkspaceOpener()

    private(set) var shelfDatabase: SQLiteDatabase?
    private(set) var airDropHistoryDatabase: SQLiteDatabase?
    private(set) var shelfService: ShelfService?
    private(set) var airDropHistoryRepository: AirDropHistoryRepository?

    /// - Parameter loginItemManager: injectable for tests; defaults to the
    ///   production `SMAppService`-backed manager.
    init(loginItemManager: LoginItemManaging = SMAppServiceLoginItemManager()) {
        self.loginItemManager = loginItemManager
    }

    /// Opens databases, applies migrations and builds the Shelf / history stacks.
    func bootstrap() throws {
        let shelfDatabase = try SQLiteDatabase(path: AppPaths.databaseURL(named: "shelf.db").path)
        try MigrationRunner(migrations: AppMigrations.shelf).migrate(shelfDatabase)
        self.shelfDatabase = shelfDatabase
        shelfService = ShelfService(
            repository: SQLiteShelfRepository(database: shelfDatabase),
            bookmarkResolver: bookmarkResolver,
            workspace: workspace
        )

        let historyDatabase = try SQLiteDatabase(path: AppPaths.databaseURL(named: "airdrop_history.db").path)
        try MigrationRunner(migrations: AppMigrations.airDropHistory).migrate(historyDatabase)
        airDropHistoryDatabase = historyDatabase
        airDropHistoryRepository = SQLiteAirDropHistoryRepository(database: historyDatabase)

        Log.app.info("Composition bootstrap complete")
    }

    /// Assembles the notch window and its dependencies. Falls back to in-memory
    /// stores if `bootstrap()` failed to open a database.
    @MainActor
    func makeNotchController() -> NotchWindowController {
        let shelfService = shelfService ?? ShelfService(
            repository: StubShelfRepository(),
            bookmarkResolver: bookmarkResolver,
            workspace: workspace
        )
        let history = airDropHistoryRepository ?? StubAirDropHistoryRepository()

        let sharingPresenter = AppKitSharingPresenter(anchor: { NSApp.windows.first { $0 is NSPanel }?.contentView })
        let tempFileWriter = (try? CacheTempFileWriter.standard()) ?? CacheTempFileWriter(
            directory: FileManager.default.temporaryDirectory
        )
        let shareService = ShareService(
            sharing: sharingPresenter,
            tempFileWriter: tempFileWriter,
            history: history
        )

        let screenProvider = AppKitScreenProvider()
        let dropCoordinator = DefaultDropCoordinator(
            shelfService: shelfService,
            shareService: shareService,
            itemFactory: ShelfItemFactory(bookmarkResolver: bookmarkResolver)
        )
        let notchViewModel = NotchViewModel(screenProvider: screenProvider, dropCoordinator: dropCoordinator)
        let shelfViewModel = ShelfViewModel(service: shelfService)

        let screenshotImporter = ScreenshotImportService(
            shelfService: shelfService,
            bookmarkResolver: bookmarkResolver
        )

        return NotchWindowController(
            viewModel: notchViewModel,
            shelfViewModel: shelfViewModel,
            screenProvider: screenProvider,
            dragMonitor: AppKitGlobalDragMonitor(),
            screenshotMonitor: DirectoryScreenshotMonitor(),
            screenshotImporter: screenshotImporter
        )
    }
}
