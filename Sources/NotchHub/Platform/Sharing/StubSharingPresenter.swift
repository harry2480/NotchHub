import Foundation

/// Test/preview ``SharingPresenting`` that records requests and replays a
/// configurable AirDrop outcome instead of showing UI.
final class StubSharingPresenter: SharingPresenting {
    private(set) var sharedURLs: [[URL]] = []
    private(set) var airDroppedURLs: [[URL]] = []
    var airDropOutcome: ShareOutcome = .sent

    func presentShareSheet(for urls: [URL]) {
        sharedURLs.append(urls)
    }

    func presentAirDrop(for urls: [URL], completion: @escaping (ShareOutcome) -> Void) {
        airDroppedURLs.append(urls)
        completion(airDropOutcome)
    }
}
