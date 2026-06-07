import Foundation

/// Which AI CLI a session belongs to (要件定義.md §13–16).
enum AISource: String, CaseIterable, Equatable, Codable {
    case claude
    case codex
    case antigravity

    var displayName: String {
        switch self {
        case .claude: "Claude"
        case .codex: "Codex"
        case .antigravity: "Antigravity"
        }
    }
}

/// A CLI session's current state (要件定義.md §13.1).
enum AISessionState: String, Equatable, Codable {
    case working
    case waitingApproval
    case idle
    case stopped
}

/// Event types received from CLI hooks over the local socket (要件定義.md §14.1).
enum AIEventType: String, Equatable, Codable {
    case sessionStart
    case userPrompt
    case preToolUse
    case permissionRequest
    case postToolUse
    case stop
    case sessionEnd
}

/// A single hook event from a CLI. Decoded from newline-delimited JSON on the
/// local socket (実装計画.md §2.3).
struct AIEvent: Equatable, Codable {
    let source: AISource
    let sessionId: String
    let type: AIEventType
    var cwd: String?
    var tool: String?
    var requestId: String?
}

/// The approval decision sent back to a CLI hook (要件定義.md §13.2).
enum ApprovalDecision: String, Equatable, Codable {
    case approve
    case deny
    case stop
}

/// A live CLI session shown in the AI tab. One per terminal (要件定義.md §16.2).
struct AISession: Identifiable, Equatable {
    let id: String
    let source: AISource
    var cwd: String?
    var state: AISessionState
    var lastTool: String?
    var pendingRequestId: String?
    var updatedAt: Date

    /// Project name derived from the working directory (要件定義.md §16.1).
    var projectName: String {
        guard let cwd, !cwd.isEmpty else { return "—" }
        return URL(fileURLWithPath: cwd).lastPathComponent
    }
}
