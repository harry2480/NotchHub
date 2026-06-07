import Foundation
@testable import NotchHub
import Testing

@MainActor
struct AIMonitorViewModelTests {
    private struct Harness {
        let viewModel: AIMonitorViewModel
        let service: AIMonitorService
        let socket: StubAISocketServer
    }

    private func makeHarness() -> Harness {
        let socket = StubAISocketServer()
        let service = AIMonitorService(socket: socket, now: { Date(timeIntervalSince1970: 1_000_000) })
        let viewModel = AIMonitorViewModel(service: service, workspace: StubWorkspaceOpener())
        return Harness(viewModel: viewModel, service: service, socket: socket)
    }

    @Test
    func reflectsSessionsAsEventsArrive() {
        let harness = makeHarness()
        harness.service.handle(AIEvent(source: .claude, sessionId: "t1", type: .sessionStart, cwd: "/p"))
        #expect(harness.viewModel.groups.count == 1)
        #expect(harness.viewModel.groups.first?.sessions.first?.id == "t1")
    }

    @Test
    func approveSendsDecisionThroughService() throws {
        let harness = makeHarness()
        harness.service.handle(AIEvent(source: .claude, sessionId: "t1", type: .permissionRequest, requestId: "r1"))
        let session = try #require(harness.viewModel.groups.first?.sessions.first)
        harness.viewModel.approve(session)
        #expect(harness.socket.responses.first?.decision == .approve)
    }
}
