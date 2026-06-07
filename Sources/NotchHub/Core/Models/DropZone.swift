import CoreGraphics

/// The three drag-drop zones shown while dragging (要件定義.md §7.3),
/// ordered left → right.
enum DropZone: Int, CaseIterable, Equatable {
    case shelf = 0 // left — keep in Shelf
    case share = 1 // centre — macOS Share Sheet
    case airDrop = 2 // right — AirDrop

    var title: String {
        switch self {
        case .shelf: "Shelf"
        case .share: "Share"
        case .airDrop: "AirDrop"
        }
    }

    var subtitle: String {
        switch self {
        case .shelf: "Keep"
        case .share: "Choose"
        case .airDrop: "Send"
        }
    }
}

/// Partitions the dragging notch frame into three drop zones separated by dead
/// zones, and hit-tests a cursor point (要件定義.md §7.4 誤操作防止).
///
/// Each third of the frame contains a centred active rect; the margins around
/// it (and the area outside the frame) are dead zones where a drop does nothing.
struct DragZoneLayout: Equatable {
    let frame: CGRect
    /// Fraction of each column/​height treated as inactive margin (0...1).
    let deadZoneRatio: CGFloat

    init(frame: CGRect, deadZoneRatio: CGFloat = 0.16) {
        self.frame = frame
        self.deadZoneRatio = min(max(deadZoneRatio, 0), 0.9)
    }

    /// The active rectangle for a given zone within `frame`.
    func rect(for zone: DropZone) -> CGRect {
        let columnWidth = frame.width / CGFloat(DropZone.allCases.count)
        let horizontalInset = columnWidth * deadZoneRatio / 2
        let verticalInset = frame.height * deadZoneRatio / 2
        let columnMinX = frame.minX + CGFloat(zone.rawValue) * columnWidth
        return CGRect(
            x: columnMinX + horizontalInset,
            y: frame.minY + verticalInset,
            width: columnWidth - horizontalInset * 2,
            height: frame.height - verticalInset * 2
        )
    }

    /// The zone under `point`, or `nil` if the point is in a dead zone or
    /// outside the frame entirely.
    func zone(at point: CGPoint) -> DropZone? {
        guard frame.contains(point) else { return nil }
        return DropZone.allCases.first { rect(for: $0).contains(point) }
    }
}
