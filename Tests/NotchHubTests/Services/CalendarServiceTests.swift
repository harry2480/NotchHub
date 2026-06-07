import Foundation
@testable import NotchHub
import Testing

struct CalendarScheduleTests {
    private let now = Date(timeIntervalSince1970: 1_000_000)
    private var calendar: Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "UTC") ?? .current
        return calendar
    }

    private func event(_ title: String, startOffset: TimeInterval, duration: TimeInterval = 3600) -> CalendarEvent {
        CalendarEvent(
            id: title,
            title: title,
            start: now.addingTimeInterval(startOffset),
            end: now.addingTimeInterval(startOffset + duration),
            isAllDay: false,
            calendarTitle: nil
        )
    }

    @Test
    func hidesFinishedEventsAndSortsByStart() {
        let past = event("past", startOffset: -7200) // ended an hour ago
        let soon = event("soon", startOffset: 1800)
        let later = event("later", startOffset: 7200)
        let schedule = CalendarSchedule.from(events: [later, past, soon], now: now, calendar: calendar)
        #expect(schedule.today.map(\.title) == ["soon", "later"])
        #expect(schedule.next?.title == "soon")
    }

    @Test
    func ongoingEventIsKept() {
        let ongoing = event("ongoing", startOffset: -600, duration: 3600) // started, not finished
        let schedule = CalendarSchedule.from(events: [ongoing], now: now, calendar: calendar)
        #expect(schedule.next?.title == "ongoing")
    }

    @Test
    func emptyWhenAllPast() {
        let schedule = CalendarSchedule.from(
            events: [event("p", startOffset: -10000)],
            now: now,
            calendar: calendar
        )
        #expect(schedule.next == nil)
        #expect(schedule.today.isEmpty)
    }

    @Test
    func todayExcludesFutureDaysButKeepsOvernightEvents() {
        let startOfDay = calendar.startOfDay(for: now)
        let overnight = CalendarEvent(
            id: "overnight",
            title: "Overnight",
            start: startOfDay.addingTimeInterval(-3600),
            end: now.addingTimeInterval(3600),
            isAllDay: false,
            calendarTitle: nil
        )
        let tomorrow = CalendarEvent(
            id: "tomorrow",
            title: "Tomorrow",
            start: startOfDay.addingTimeInterval(90000),
            end: startOfDay.addingTimeInterval(93600),
            isAllDay: false,
            calendarTitle: nil
        )

        let schedule = CalendarSchedule.from(events: [tomorrow, overnight], now: now, calendar: calendar)

        #expect(schedule.next?.id == "overnight")
        #expect(schedule.today.map(\.id) == ["overnight"])
    }
}

struct CalendarServiceTests {
    @Test
    func scheduleUsesProviderEvents() throws {
        let now = Date(timeIntervalSince1970: 1_000_000)
        let upcoming = CalendarEvent(
            id: "e",
            title: "Standup",
            start: now.addingTimeInterval(600),
            end: now.addingTimeInterval(1200),
            isAllDay: false,
            calendarTitle: "Work"
        )
        let provider = StubCalendarProvider(events: [upcoming])
        let service = CalendarService(provider: provider, workspace: StubWorkspaceOpener(), now: { now })
        #expect(try service.schedule().next?.title == "Standup")
    }
}
