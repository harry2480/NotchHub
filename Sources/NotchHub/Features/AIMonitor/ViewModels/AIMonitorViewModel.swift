import Foundation
import Observation

/// Sessions for one CLI source, for display grouping (要件定義.md §16.1).
struct AISessionGroup: Identifiable {
    let source: AISource
    let sessions: [AISession]
    var id: AISource {
        source
    }
}

/// Drives the AI tab (要件定義.md §13, §16): session list and Approve / Deny /
/// Stop. Mirrors ``AIMonitorService`` state.
@MainActor
@Observable
final class AIMonitorViewModel {
    private(set) var groups: [AISessionGroup] = []

    private let service: AIMonitorService
    private let workspace: WorkspaceOpening

    init(service: AIMonitorService, workspace: WorkspaceOpening) {
        self.service = service
        self.workspace = workspace
        service.onSessionsChanged = { [weak self] in self?.refresh() }
        refresh()
    }

    func refresh() {
        groups = service.groupedBySource().map { AISessionGroup(source: $0.source, sessions: $0.sessions) }
    }

    func approve(_ session: AISession) {
        service.respond(sessionId: session.id, decision: .approve)
    }

    func deny(_ session: AISession) {
        service.respond(sessionId: session.id, decision: .deny)
    }

    func stop(_ session: AISession) {
        service.respond(sessionId: session.id, decision: .stop)
    }

    /// Reveals the session's working directory (要件定義.md §13.2 Open Terminal —
    /// MVP reveals the project folder).
    func reveal(_ session: AISession) {
        guard let cwd = session.cwd, !cwd.isEmpty else { return }
        workspace.revealInFinder(URL(fileURLWithPath: cwd))
    }
}
