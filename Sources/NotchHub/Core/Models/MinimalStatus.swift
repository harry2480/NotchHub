/// What the collapsed notch surfaces. Only ONE status is shown at a time, by
/// priority (要件定義.md §6.2). Lower `rawValue` means higher priority.
enum MinimalStatus: Int, CaseIterable, Equatable {
    case aiApprovalWaiting = 0
    case dragging = 1
    case sharing = 2
    case mediaPlaying = 3
    case upcomingEvent = 4

    /// Resolves the single highest-priority status among the active signals,
    /// or `nil` when nothing is active (the notch stays fully assimilated).
    static func resolve(from active: Set<MinimalStatus>) -> MinimalStatus? {
        active.min { $0.rawValue < $1.rawValue }
    }

    /// A short glyph shown in the collapsed notch (要件定義.md §6.3).
    var glyph: String {
        switch self {
        case .aiApprovalWaiting: "!"
        case .dragging: "⤓"
        case .sharing: "✓"
        case .mediaPlaying: "⏯"
        case .upcomingEvent: "•"
        }
    }
}
