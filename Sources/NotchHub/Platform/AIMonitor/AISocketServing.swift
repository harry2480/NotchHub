/// Receives CLI hook events over a local socket and sends approval responses
/// back (実装計画.md §2.3). Hides the Unix domain socket behind a protocol.
protocol AISocketServing: AnyObject {
    var onEvent: ((AIEvent) -> Void)? { get set }
    func start()
    func stop()
    func respond(requestId: String, decision: ApprovalDecision)
}
