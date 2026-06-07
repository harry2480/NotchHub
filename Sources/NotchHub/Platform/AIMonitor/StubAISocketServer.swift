/// Test/preview ``AISocketServing`` driven manually.
final class StubAISocketServer: AISocketServing {
    var onEvent: ((AIEvent) -> Void)?
    private(set) var isRunning = false
    private(set) var responses: [(requestId: String, decision: ApprovalDecision)] = []

    func start() {
        isRunning = true
    }

    func stop() {
        isRunning = false
    }

    func respond(requestId: String, decision: ApprovalDecision) {
        responses.append((requestId, decision))
    }

    /// Simulates receiving an event from a CLI hook.
    func emit(_ event: AIEvent) {
        onEvent?(event)
    }
}
