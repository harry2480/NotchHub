/// Result of an AirDrop / Share attempt (要件定義.md §10.5 結果).
enum ShareOutcome: String, Equatable {
    case sent
    case failed
    case cancelled
}

/// What to do with the source after an AirDrop completes (要件定義.md §10.3/§10.4).
enum AirDropPostSendAction: Equatable {
    case keep
    case delete
}
