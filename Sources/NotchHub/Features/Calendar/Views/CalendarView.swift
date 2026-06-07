import SwiftUI

/// The Calendar tab: the next event and today's remaining events
/// (要件定義.md §17.1). Tapping opens Calendar.app.
struct CalendarView: View {
    let viewModel: CalendarViewModel

    var body: some View {
        Group {
            if viewModel.accessDenied {
                message("Calendar access not granted", systemImage: "calendar.badge.exclamationmark")
            } else if viewModel.schedule.today.isEmpty {
                message("No upcoming events", systemImage: "calendar")
            } else {
                content
            }
        }
        .task { await viewModel.load() }
    }

    private var content: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                if let next = viewModel.schedule.next {
                    section(title: "Next") {
                        eventRow(next, emphasized: true)
                    }
                }
                section(title: "Today") {
                    ForEach(viewModel.schedule.today) { event in
                        eventRow(event, emphasized: false)
                    }
                }
            }
            .padding(NotchStyle.contentPadding)
        }
        .onTapGesture { viewModel.openCalendarApp() }
    }

    private func section(title: String, @ViewBuilder _ rows: () -> some View) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)
            rows()
        }
    }

    private func eventRow(_ event: CalendarEvent, emphasized: Bool) -> some View {
        HStack(spacing: 8) {
            Text(event.isAllDay ? "All day" : Self.timeFormatter.string(from: event.start))
                .font(.callout.monospacedDigit())
                .foregroundStyle(.secondary)
                .frame(width: 64, alignment: .leading)
            Text(event.title)
                .font(emphasized ? .headline : .callout)
                .lineLimit(1)
            Spacer(minLength: 0)
        }
    }

    private func message(_ text: String, systemImage: String) -> some View {
        VStack(spacing: 6) {
            Image(systemName: systemImage)
                .font(.system(size: 26))
                .foregroundStyle(.secondary)
            Text(text)
                .font(.callout)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private static let timeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        formatter.dateStyle = .none
        return formatter
    }()
}
