/// Tabs shown in the expanded notch (要件定義.md §12). Shelf is the default;
/// the initial tab becomes configurable in Settings (Phase 4).
enum NotchTab: String, CaseIterable, Identifiable, Equatable {
    case shelf
    case calendar
    case media
    case ai

    var id: String {
        rawValue
    }

    var title: String {
        switch self {
        case .shelf: "Shelf"
        case .calendar: "Calendar"
        case .media: "Media"
        case .ai: "AI"
        }
    }
}
