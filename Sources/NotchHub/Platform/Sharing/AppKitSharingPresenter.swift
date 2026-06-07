import AppKit

/// Production ``SharingPresenting`` using `NSSharingServicePicker` for the Share
/// Sheet and the AirDrop sharing service. Anchored to the notch panel so the
/// sheet appears under the notch. Invoked on the main thread (from drop
/// handling), matching the AppKit requirement.
final class AppKitSharingPresenter: NSObject, SharingPresenting {
    private let anchor: () -> NSView?
    /// Keyed by identity so concurrent AirDrops don't clobber each other's
    /// delegate (`NSSharingService.delegate` is weak, so we must retain it until
    /// its callback fires).
    private var activeDelegates: [ObjectIdentifier: AirDropDelegate] = [:]

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
        let delegate = AirDropDelegate(completion: completion)
        let key = ObjectIdentifier(delegate)
        delegate.onFinish = { [weak self] in self?.activeDelegates[key] = nil }
        activeDelegates[key] = delegate
        service.delegate = delegate
        service.perform(withItems: urls)
    }
}

/// Captures the AirDrop sharing service outcome via its delegate callbacks and
/// reports completion exactly once.
private final class AirDropDelegate: NSObject, NSSharingServiceDelegate {
    private let completion: (ShareOutcome) -> Void
    var onFinish: (() -> Void)?
    private var finished = false

    init(completion: @escaping (ShareOutcome) -> Void) {
        self.completion = completion
    }

    private func finish(_ outcome: ShareOutcome) {
        guard !finished else { return }
        finished = true
        completion(outcome)
        onFinish?()
    }

    func sharingService(_: NSSharingService, didShareItems _: [Any]) {
        finish(.sent)
    }

    func sharingService(_: NSSharingService, didFailToShareItems _: [Any], error: Error) {
        let cancelled = (error as NSError).code == NSUserCancelledError
        finish(cancelled ? .cancelled : .failed)
    }
}
