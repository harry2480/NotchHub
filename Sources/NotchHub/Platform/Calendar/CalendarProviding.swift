import Foundation

/// Supplies calendar events, hiding EventKit behind a protocol (AGENTS.md). The
/// Calendar permission is requested on demand (要件定義.md §21).
protocol CalendarProviding {
    func requestAccessIfNeeded() async -> Bool
    func events(from start: Date, to end: Date) throws -> [CalendarEvent]
}
