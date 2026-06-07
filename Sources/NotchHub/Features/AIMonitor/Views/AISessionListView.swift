import SwiftUI

/// The AI tab: CLI sessions grouped by source, each showing state and (when
/// waiting) Approve / Deny / Stop (要件定義.md §13, §16).
struct AISessionListView: View {
    let viewModel: AIMonitorViewModel

    var body: some View {
        Group {
            if viewModel.groups.isEmpty {
                VStack(spacing: 6) {
                    Image(systemName: "terminal")
                        .font(.system(size: 26))
                        .foregroundStyle(.secondary)
                    Text("No active sessions")
                        .font(.callout)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 12) {
                        ForEach(viewModel.groups) { group in
                            section(group)
                        }
                    }
                    .padding(NotchStyle.contentPadding)
                }
            }
        }
        .onAppear { viewModel.refresh() }
    }

    private func section(_ group: AISessionGroup) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(group.source.displayName)
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)
            ForEach(group.sessions) { session in
                row(session)
            }
        }
    }

    private func row(_ session: AISession) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 8) {
                Circle()
                    .fill(color(for: session.state))
                    .frame(width: 8, height: 8)
                Text(session.projectName)
                    .font(.callout.weight(.medium))
                    .lineLimit(1)
                Spacer(minLength: 0)
                if let tool = session.lastTool {
                    Text(tool)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
            }
            .contentShape(Rectangle())
            .onTapGesture { viewModel.reveal(session) }

            if session.state == .waitingApproval {
                ApprovalPromptView(
                    onApprove: { viewModel.approve(session) },
                    onDeny: { viewModel.deny(session) },
                    onStop: { viewModel.stop(session) }
                )
            }
        }
    }

    private func color(for state: AISessionState) -> Color {
        switch state {
        case .working: .green
        case .waitingApproval: .orange
        case .idle: .secondary
        case .stopped: .red
        }
    }
}
