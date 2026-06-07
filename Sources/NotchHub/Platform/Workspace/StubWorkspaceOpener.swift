import Foundation

/// Test/preview ``WorkspaceOpening`` that records requests instead of touching
/// the real workspace.
final class StubWorkspaceOpener: WorkspaceOpening {
    private(set) var opened: [URL] = []
    private(set) var revealed: [URL] = []

    func open(_ url: URL) {
        opened.append(url)
    }

    func revealInFinder(_ url: URL) {
        revealed.append(url)
    }
}
