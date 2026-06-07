import SwiftUI

/// Approve / Deny / Stop controls shown for a session awaiting approval
/// (要件定義.md §13.2).
struct ApprovalPromptView: View {
    let onApprove: () -> Void
    let onDeny: () -> Void
    let onStop: () -> Void

    var body: some View {
        HStack(spacing: 8) {
            Button("Approve", action: onApprove)
                .buttonStyle(.borderedProminent)
            Button("Deny", action: onDeny)
                .buttonStyle(.bordered)
            Button("Stop", role: .destructive, action: onStop)
                .buttonStyle(.bordered)
        }
        .controlSize(.small)
        .font(.caption)
    }
}
