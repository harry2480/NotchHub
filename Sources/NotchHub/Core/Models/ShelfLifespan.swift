import Foundation

/// How long unpinned Shelf items live before automatic removal
/// (要件定義.md §8.9). Pinned items are exempt from expiry.
enum ShelfLifespan: Equatable, Hashable {
    case forever
    case days(Int)

    static let sevenDays = ShelfLifespan.days(7)
    static let thirtyDays = ShelfLifespan.days(30)

    private static let secondsPerDay: TimeInterval = 86400

    /// The expiry instant for an item created at `createdAt`, or `nil` if it
    /// never expires.
    func expiryDate(from createdAt: Date) -> Date? {
        switch self {
        case .forever:
            nil
        case let .days(count):
            // Guard against corrupted/non-positive values, which would otherwise
            // make every item instantly expired. Treat them as "never expires".
            count > 0 ? createdAt.addingTimeInterval(TimeInterval(count) * Self.secondsPerDay) : nil
        }
    }

    /// Whether an item created at `createdAt` has expired by `now`.
    func isExpired(createdAt: Date, now: Date) -> Bool {
        guard let expiry = expiryDate(from: createdAt) else { return false }
        return now >= expiry
    }
}
