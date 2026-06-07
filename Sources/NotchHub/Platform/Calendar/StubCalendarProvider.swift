import Foundation

/// Test/preview ``CalendarProviding`` returning fixed events.
final class StubCalendarProvider: CalendarProviding {
    var accessGranted: Bool
    var fixtureEvents: [CalendarEvent]

    init(accessGranted: Bool = true, events: [CalendarEvent] = []) {
        self.accessGranted = accessGranted
        fixtureEvents = events
    }

    func requestAccessIfNeeded() async -> Bool {
        accessGranted
    }

    func events(from start: Date, to end: Date) throws -> [CalendarEvent] {
        fixtureEvents.filter { $0.start < end && $0.end > start }
    }
}
