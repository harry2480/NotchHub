import Foundation

/// A calendar event for display (要件定義.md §17). Sourced from EventKit via the
/// Platform layer; this model carries no EventKit types.
struct CalendarEvent: Identifiable, Equatable {
    let id: String
    let title: String
    let start: Date
    let end: Date
    let isAllDay: Bool
    let calendarTitle: String?
}

/// The "Next" event and today's remaining events (要件定義.md §17.1). Past events
/// are hidden (要件定義.md §17.2).
struct CalendarSchedule: Equatable {
    let next: CalendarEvent?
    let today: [CalendarEvent]

    static let empty = CalendarSchedule(next: nil, today: [])

    /// Builds the schedule from events, hiding those already finished and
    /// ordering by start time. `next` is the soonest remaining event.
    static func from(events: [CalendarEvent], now: Date) -> CalendarSchedule {
        let remaining = events
            .filter { $0.end > now }
            .sorted { $0.start < $1.start }
        return CalendarSchedule(next: remaining.first, today: remaining)
    }
}
