import Foundation

/// Maintains live CLI sessions from socket events and routes approval decisions
/// back (要件定義.md §13–16). The state machine is pure and testable; the socket
/// is injected.
final class AIMonitorService {
    private(set) var sessions: [AISession] = []

    /// Called when a session needs approval, so the notch can auto-expand
    /// (要件定義.md §13.3).
    var onApprovalNeeded: ((AISession) -> Void)?
    /// Called whenever the session list changes, so view models can refresh.
    var onSessionsChanged: (() -> Void)?

    private let socket: AISocketServing
    private let now: () -> Date

    init(socket: AISocketServing, now: @escaping () -> Date = Date.init) {
        self.socket = socket
        self.now = now
    }

    func start() {
        socket.onEvent = { [weak self] event in self?.handle(event) }
        socket.start()
    }

    func stop() {
        socket.stop()
    }

    /// Applies a hook event to the session model.
    func handle(_ event: AIEvent) {
        switch event.type {
        case .sessionStart:
            upsert(event, state: .idle)
        case .userPrompt, .preToolUse, .postToolUse:
            upsert(event, state: .working)
        case .permissionRequest:
            let session = upsert(event, state: .waitingApproval, pendingRequestId: event.requestId)
            onApprovalNeeded?(session)
        case .stop:
            upsert(event, state: .idle, clearPending: true)
        case .sessionEnd:
            remove(event.sessionId)
        }
        onSessionsChanged?()
    }

    /// Responds to a session's pending approval (要件定義.md §13.2).
    func respond(sessionId: String, decision: ApprovalDecision) {
        guard let index = sessions.firstIndex(where: { $0.id == sessionId }),
              let requestId = sessions[index].pendingRequestId else { return }
        socket.respond(requestId: requestId, decision: decision)
        sessions[index].pendingRequestId = nil
        sessions[index].state = decision == .stop ? .stopped : .working
        sessions[index].updatedAt = now()
        onSessionsChanged?()
    }

    /// Sessions grouped by source in stable display order (要件定義.md §16.1).
    func groupedBySource() -> [(source: AISource, sessions: [AISession])] {
        AISource.allCases.compactMap { source in
            let matching = sessions.filter { $0.source == source }
            return matching.isEmpty ? nil : (source, matching)
        }
    }

    // MARK: - Private

    @discardableResult
    private func upsert(
        _ event: AIEvent,
        state: AISessionState,
        pendingRequestId: String? = nil,
        clearPending: Bool = false
    ) -> AISession {
        if let index = sessions.firstIndex(where: { $0.id == event.sessionId }) {
            sessions[index].state = state
            sessions[index].updatedAt = now()
            if let cwd = event.cwd { sessions[index].cwd = cwd }
            if let tool = event.tool { sessions[index].lastTool = tool }
            if let pendingRequestId { sessions[index].pendingRequestId = pendingRequestId }
            if clearPending { sessions[index].pendingRequestId = nil }
            return sessions[index]
        }
        let session = AISession(
            id: event.sessionId,
            source: event.source,
            cwd: event.cwd,
            state: state,
            lastTool: event.tool,
            pendingRequestId: pendingRequestId,
            updatedAt: now()
        )
        sessions.append(session)
        return session
    }

    private func remove(_ sessionId: String) {
        sessions.removeAll { $0.id == sessionId }
    }
}
