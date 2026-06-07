import Foundation

/// Opens files/URLs and reveals them in Finder, hiding `NSWorkspace` behind a
/// protocol (AGENTS.md: OS API は Platform 層に隠蔽).
protocol WorkspaceOpening {
    func open(_ url: URL)
    func revealInFinder(_ url: URL)
}
