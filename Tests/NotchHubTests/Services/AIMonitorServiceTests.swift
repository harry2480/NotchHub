import Foundation
@testable import NotchHub
import Testing

struct AIMonitorServiceTests {
    private func makeService() -> (AIMonitorService, StubAISocketServer) {
        let socket = StubAISocketServer()
        let service = AIMonitorService(
            socket: socket,
            workspace: StubWorkspaceOpener(),
            now: { Date(timeIntervalSince1970: 1_000_000) }
        )
        return (service, socket)
    }

    private func event(
        _ type: AIEventType,
        session: String = "term-1",
        tool: String? = nil,
        requestId: String? = nil
    ) -> AIEvent {
        AIEvent(source: .claude, sessionId: session, type: type, cwd: "/Users/x/proj", tool: tool, requestId: requestId)
    }

    @Test
    func sessionStartCreatesIdleSession() {
        let (service, _) = makeService()
        service.handle(event(.sessionStart))
        #expect(service.sessions.count == 1)
        #expect(service.sessions.first?.state == .idle)
        #expect(service.sessions.first?.projectName == "proj")
    }

    @Test
    func preToolUseMarksWorkingWithTool() {
        let (service, _) = makeService()
        service.handle(event(.sessionStart))
        service.handle(event(.preToolUse, tool: "Bash"))
        #expect(service.sessions.first?.state == .working)
        #expect(service.sessions.first?.lastTool == "Bash")
    }

    @Test
    func permissionRequestWaitsAndNotifies() {
        let (service, _) = makeService()
        var notified: AISession?
        service.onApprovalNeeded = { notified = $0 }
        service.handle(event(.permissionRequest, requestId: "req-1"))
        #expect(service.sessions.first?.state == .waitingApproval)
        #expect(service.sessions.first?.pendingRequestId == "req-1")
        #expect(notified?.id == "term-1")
    }

    @Test
    func respondSendsDecisionAndClearsPending() {
        let (service, socket) = makeService()
        service.handle(event(.permissionRequest, requestId: "req-1"))
        service.respond(sessionId: "term-1", decision: .approve)
        #expect(socket.responses.first?.requestId == "req-1")
        #expect(socket.responses.first?.decision == .approve)
        #expect(service.sessions.first?.pendingRequestId == nil)
        #expect(service.sessions.first?.state == .working)
    }

    @Test
    func stopDecisionMarksStopped() {
        let (service, _) = makeService()
        service.handle(event(.permissionRequest, requestId: "req-1"))
        service.respond(sessionId: "term-1", decision: .stop)
        #expect(service.sessions.first?.state == .stopped)
    }

    @Test
    func sessionEndRemovesSession() {
        let (service, _) = makeService()
        service.handle(event(.sessionStart))
        service.handle(event(.sessionEnd))
        #expect(service.sessions.isEmpty)
    }

    @Test
    func groupedBySourceOrdersByCLI() {
        let (service, _) = makeService()
        service.handle(AIEvent(source: .codex, sessionId: "c1", type: .sessionStart))
        service.handle(AIEvent(source: .claude, sessionId: "a1", type: .sessionStart))
        let groups = service.groupedBySource()
        #expect(groups.map(\.source) == [.claude, .codex]) // allCases order
    }
}
