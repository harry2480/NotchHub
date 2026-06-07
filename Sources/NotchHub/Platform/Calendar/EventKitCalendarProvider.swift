import EventKit

/// Production ``CalendarProviding`` backed by EventKit (要件定義.md §17).
final class EventKitCalendarProvider: CalendarProviding {
    private let store = EKEventStore()

    func requestAccessIfNeeded() async -> Bool {
        await (try? store.requestFullAccessToEvents()) ?? false
    }

    func events(from start: Date, to end: Date) throws -> [CalendarEvent] {
        let predicate = store.predicateForEvents(withStart: start, end: end, calendars: nil)
        return store.events(matching: predicate).map { event in
            CalendarEvent(
                id: event.eventIdentifier ?? "\(event.startDate.timeIntervalSince1970)-\(event.title ?? "")",
                title: event.title ?? "(No title)",
                start: event.startDate,
                end: event.endDate,
                isAllDay: event.isAllDay,
                calendarTitle: event.calendar?.title
            )
        }
    }
}
