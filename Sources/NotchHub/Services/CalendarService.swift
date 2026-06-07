import Foundation

/// Builds the day's ``CalendarSchedule`` from the Platform provider
/// (要件定義.md §17). Fetches today's window and delegates filtering/ordering to
/// the pure ``CalendarSchedule/from(events:now:)``.
final class CalendarService {
    private let provider: CalendarProviding
    private let workspace: WorkspaceOpening
    private let calendar: Calendar
    private let now: () -> Date

    init(
        provider: CalendarProviding,
        workspace: WorkspaceOpening,
        calendar: Calendar = .current,
        now: @escaping () -> Date = Date.init
    ) {
        self.provider = provider
        self.workspace = workspace
        self.calendar = calendar
        self.now = now
    }

    func requestAccessIfNeeded() async -> Bool {
        await provider.requestAccessIfNeeded()
    }

    /// How many days ahead to fetch so "Next" / "Upcoming" can surface events on
    /// later days, not only today (要件定義.md §17.1).
    private static let horizonDays = 7

    func schedule() throws -> CalendarSchedule {
        let current = now()
        let startOfDay = calendar.startOfDay(for: current)
        guard let horizonEnd = calendar.date(byAdding: .day, value: Self.horizonDays, to: startOfDay) else {
            return .empty
        }
        let events = try provider.events(from: startOfDay, to: horizonEnd)
        return CalendarSchedule.from(events: events, now: current, calendar: calendar)
    }

    /// Opens Calendar.app (要件定義.md §17.2). Lives in the Service so the
    /// ViewModel never touches the OS directly.
    func openCalendarApp() {
        guard let url = URL(string: "ical://") else { return }
        workspace.open(url)
    }
}
