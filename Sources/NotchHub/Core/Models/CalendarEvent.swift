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

/// The "Next" event, today's remaining events, and upcoming events on later
/// days (要件定義.md §17.1). Past events are hidden (要件定義.md §17.2).
struct CalendarSchedule: Equatable {
    /// The soonest remaining event across the whole fetched window — may be on a
    /// later day when there is nothing left today.
    let next: CalendarEvent?
    /// Remaining events on the current calendar day.
    let today: [CalendarEvent]
    /// Remaining events on later days (within the fetch horizon).
    let upcoming: [CalendarEvent]

    static let empty = CalendarSchedule(next: nil, today: [], upcoming: [])

    /// True when there is nothing left to show at all.
    var isEmpty: Bool {
        next == nil && today.isEmpty && upcoming.isEmpty
    }

    /// Builds the schedule from events, hiding those already finished and
    /// ordering by start time. `next` is the soonest remaining event (any day);
    /// `today` is restricted to the current calendar day; `upcoming` holds the
    /// remaining events that start on a later day.
    static func from(events: [CalendarEvent], now: Date, calendar: Calendar = .current) -> CalendarSchedule {
        let remaining = events
            .filter { $0.end > now }
            .sorted { $0.start < $1.start }
        let startOfDay = calendar.startOfDay(for: now)
        let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay)
        let today = remaining.filter { event in
            guard let endOfDay else { return calendar.isDate(event.start, inSameDayAs: now) }
            return event.start < endOfDay && event.end > startOfDay
        }
        let upcoming = remaining.filter { event in
            guard let endOfDay else { return !calendar.isDate(event.start, inSameDayAs: now) }
            return event.start >= endOfDay
        }
        return CalendarSchedule(next: remaining.first, today: today, upcoming: upcoming)
    }
}
