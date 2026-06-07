import Foundation

/// Composition Root — the single place where concrete implementations are wired
/// to their protocols (アーキテクチャ.md). No other layer constructs adapters or
/// repositories directly.
///
/// `bootstrap()` opens the database and builds the Shelf stack; the factory
/// methods assemble the notch window and its view models. Later phases extend
/// this with the AirDrop / Share / AI services they introduce.
final class AppComposition {
    let loginItemManager: LoginItemManaging

    private let bookmarkResolver: BookmarkResolving = SecurityScopedBookmarkResolver()
    private let workspace: WorkspaceOpening = AppKitWorkspaceOpener()

    private(set) var shelfDatabase: SQLiteDatabase?
    private(set) var shelfService: ShelfService?

    /// - Parameter loginItemManager: injectable for tests; defaults to the
    ///   production `SMAppService`-backed manager.
    init(loginItemManager: LoginItemManaging = SMAppServiceLoginItemManager()) {
        self.loginItemManager = loginItemManager
    }

    /// Opens databases, applies migrations and builds the Shelf service.
    func bootstrap() throws {
        let databaseURL = try AppPaths.databaseURL(named: "shelf.db")
        let database = try SQLiteDatabase(path: databaseURL.path)
        try MigrationRunner(migrations: AppMigrations.shelf).migrate(database)
        shelfDatabase = database
        shelfService = ShelfService(
            repository: SQLiteShelfRepository(database: database),
            bookmarkResolver: bookmarkResolver,
            workspace: workspace
        )
        Log.app.info("Composition bootstrap complete")
    }

    /// Assembles the notch window and its dependencies. Falls back to an
    /// in-memory Shelf if `bootstrap()` failed to open the database.
    @MainActor
    func makeNotchController() -> NotchWindowController {
        let service = shelfService ?? ShelfService(
            repository: StubShelfRepository(),
            bookmarkResolver: bookmarkResolver,
            workspace: workspace
        )
        let screenProvider = AppKitScreenProvider()
        let dropCoordinator = DefaultDropCoordinator(
            shelfService: service,
            itemFactory: ShelfItemFactory(bookmarkResolver: bookmarkResolver)
        )
        let notchViewModel = NotchViewModel(screenProvider: screenProvider, dropCoordinator: dropCoordinator)
        let shelfViewModel = ShelfViewModel(service: service)
        let dragMonitor = AppKitGlobalDragMonitor()
        return NotchWindowController(
            viewModel: notchViewModel,
            shelfViewModel: shelfViewModel,
            screenProvider: screenProvider,
            dragMonitor: dragMonitor
        )
    }
}
