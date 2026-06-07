/// User-configurable settings (要件定義.md §20). Pure value type; persistence
/// and serialization live in the Settings repository.
struct AppSettings: Equatable {
    var lifespan: ShelfLifespan
    var airDropPostSend: AirDropPostSendAction
    var screenshotAutoImport: Bool
    var initialTab: NotchTab
    var pseudoNotchEnabled: Bool
    var showAI: Bool
    var showCalendar: Bool
    var showMedia: Bool

    static let `default` = AppSettings(
        lifespan: .forever,
        airDropPostSend: .keep,
        screenshotAutoImport: true,
        initialTab: .shelf,
        pseudoNotchEnabled: true,
        showAI: true,
        showCalendar: true,
        showMedia: true
    )
}

extension ShelfLifespan {
    /// Stable string form for persistence (`forever` or `days:<n>`).
    var storageValue: String {
        switch self {
        case .forever: "forever"
        case let .days(count): "days:\(count)"
        }
    }

    init(storageValue: String) {
        if storageValue.hasPrefix("days:"), let count = Int(storageValue.dropFirst("days:".count)) {
            self = .days(count)
        } else {
            self = .forever
        }
    }
}

extension AirDropPostSendAction {
    var storageValue: String {
        self == .delete ? "delete" : "keep"
    }

    init(storageValue: String) {
        self = storageValue == "delete" ? .delete : .keep
    }
}
