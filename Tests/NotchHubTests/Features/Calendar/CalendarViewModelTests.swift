import Foundation
@testable import NotchHub
import Testing

@MainActor
struct CalendarViewModelTests {
    @Test
    func loadPopulatesScheduleWhenGranted() async {
        let now = Date(timeIntervalSince1970: 1_000_000)
        let event = CalendarEvent(
            id: "e",
            title: "Standup",
            start: now.addingTimeInterval(600),
            end: now.addingTimeInterval(1200),
            isAllDay: false,
            calendarTitle: nil
        )
        let provider = StubCalendarProvider(accessGranted: true, events: [event])
        let service = CalendarService(provider: provider, workspace: StubWorkspaceOpener(), now: { now })
        let viewModel = CalendarViewModel(service: service)

        await viewModel.load()
        #expect(!viewModel.accessDenied)
        #expect(viewModel.schedule.next?.title == "Standup")
    }

    @Test
    func loadSetsAccessDeniedWhenNotGranted() async {
        let provider = StubCalendarProvider(accessGranted: false)
        let service = CalendarService(provider: provider, workspace: StubWorkspaceOpener())
        let viewModel = CalendarViewModel(service: service)

        await viewModel.load()
        #expect(viewModel.accessDenied)
    }

    @Test
    func openCalendarAppDelegatesToWorkspace() {
        let workspace = StubWorkspaceOpener()
        let viewModel = CalendarViewModel(
            service: CalendarService(provider: StubCalendarProvider(), workspace: workspace)
        )
        viewModel.openCalendarApp()
        #expect(workspace.opened.first?.scheme == "ical")
    }
}
