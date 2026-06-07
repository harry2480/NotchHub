import CoreGraphics

/// Snapshot of an in-progress drag over the notch (要件定義.md §7).
struct DragSession: Equatable {
    /// Cursor position in global coordinates.
    var cursor: CGPoint
    /// The display whose notch is currently targeted.
    var screenID: ScreenInfo.ID
    /// The drop zone under the cursor, or `nil` when over a dead zone.
    var hoveredZone: DropZone?
}
