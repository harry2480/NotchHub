/// Decides what happens when items are dropped on a zone and produces the toast
/// to show. Phase 1 ships a placeholder/stub implementation; Phase 2/3 wire the
/// real Shelf / AirDrop / Share behaviour behind this same protocol.
protocol DropCoordinating {
    /// Handles a completed drop and returns the toast to surface.
    func handle(_ request: DropRequest) -> ToastMessage
    /// Reverses the given request if it was undoable.
    func undo(_ request: DropRequest)
}
