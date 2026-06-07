/// Placeholder ``DropCoordinating`` used until the Shelf / AirDrop / Share
/// services exist (Phase 2/3). It records calls (handy for tests) and logs, and
/// returns a zone-appropriate toast. Only the Shelf zone is treated as undoable.
final class StubDropCoordinator: DropCoordinating {
    private(set) var handled: [DropRequest] = []
    private(set) var undone: [DropRequest] = []

    func handle(_ request: DropRequest) -> ToastMessage {
        handled.append(request)
        Log.notch.info("Drop handled: zone=\(request.zone.title, privacy: .public) items=\(request.items.count)")
        let count = request.items.count
        switch request.zone {
        case .shelf:
            return ToastMessage(text: "Added \(count) to Shelf", isUndoable: true)
        case .share:
            return ToastMessage(text: "Opening Share…")
        case .airDrop:
            return ToastMessage(text: "Opening AirDrop…")
        }
    }

    func undo(_ request: DropRequest) {
        undone.append(request)
        Log.notch.info("Drop undone: zone=\(request.zone.title, privacy: .public)")
    }
}
