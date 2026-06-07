import Foundation
import Observation

/// Drives the Calendar tab (要件定義.md §17): Next + Today, opening Calendar.app.
@MainActor
@Observable
final class CalendarViewModel {
    private(set) var schedule: CalendarSchedule = .empty
    private(set) var accessDenied = false

    private let service: CalendarService
    private let workspace: WorkspaceOpening

    init(service: CalendarService, workspace: WorkspaceOpening) {
        self.service = service
        self.workspace = workspace
    }

    func load() async {
        guard await service.requestAccessIfNeeded() else {
            accessDenied = true
            schedule = .empty
            return
        }
        accessDenied = false
        schedule = (try? service.schedule()) ?? .empty
    }

    /// Opens Calendar.app (要件定義.md §17.2 クリックで起動).
    func openCalendarApp() {
        if let url = URL(string: "ical://") {
            workspace.open(url)
        }
    }
}
