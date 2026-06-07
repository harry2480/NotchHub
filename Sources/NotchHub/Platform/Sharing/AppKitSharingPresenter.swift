import AppKit

/// Production ``SharingPresenting`` using `NSSharingServicePicker` for the Share
/// Sheet and the AirDrop sharing service. Anchored to the notch panel so the
/// sheet appears under the notch. Invoked on the main thread (from drop
/// handling), matching the AppKit requirement.
final class AppKitSharingPresenter: NSObject, SharingPresenting {
    private let anchor: () -> NSView?
    private var activeDelegate: AirDropDelegate?

    init(anchor: @escaping () -> NSView?) {
        self.anchor = anchor
    }

    func presentShareSheet(for urls: [URL]) {
        guard !urls.isEmpty, let view = anchor() else { return }
        let picker = NSSharingServicePicker(items: urls)
        picker.show(relativeTo: view.bounds, of: view, preferredEdge: .minY)
    }

    func presentAirDrop(for urls: [URL], completion: @escaping (ShareOutcome) -> Void) {
        guard !urls.isEmpty, let service = NSSharingService(named: .sendViaAirDrop) else {
            completion(.failed)
            return
        }
        let delegate = AirDropDelegate { [weak self] outcome in
            completion(outcome)
            self?.activeDelegate = nil
        }
        activeDelegate = delegate
        service.delegate = delegate
        service.perform(withItems: urls)
    }
}

/// Captures the AirDrop sharing service outcome via its delegate callbacks.
private final class AirDropDelegate: NSObject, NSSharingServiceDelegate {
    private let completion: (ShareOutcome) -> Void

    init(completion: @escaping (ShareOutcome) -> Void) {
        self.completion = completion
    }

    func sharingService(_: NSSharingService, didShareItems _: [Any]) {
        completion(.sent)
    }

    func sharingService(_: NSSharingService, didFailToShareItems _: [Any], error: Error) {
        let cancelled = (error as NSError).code == NSUserCancelledError
        completion(cancelled ? .cancelled : .failed)
    }
}
