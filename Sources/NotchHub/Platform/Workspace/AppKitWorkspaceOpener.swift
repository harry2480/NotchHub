import AppKit

/// Production ``WorkspaceOpening`` backed by `NSWorkspace`.
final class AppKitWorkspaceOpener: WorkspaceOpening {
    func open(_ url: URL) {
        NSWorkspace.shared.open(url)
    }

    func revealInFinder(_ url: URL) {
        NSWorkspace.shared.activateFileViewerSelecting([url])
    }
}
