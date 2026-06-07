import Foundation

/// Production ``ScreenshotMonitoring`` that watches the macOS screenshot save
/// location for new image files (実装計画.md §Phase 3). New image files in that
/// directory are treated as screenshots. Uses a `DispatchSource` directory
/// watcher; callbacks are marshalled to the main thread.
final class DirectoryScreenshotMonitor: ScreenshotMonitoring {
    var onScreenshot: ((URL) -> Void)?

    private let directory: URL
    private let fileManager: FileManager
    private var source: DispatchSourceFileSystemObject?
    private var descriptor: Int32 = -1
    private var seen: Set<URL> = []

    private static let imageExtensions: Set<String> = ["png", "jpg", "jpeg", "heic"]

    init(directory: URL = DirectoryScreenshotMonitor.defaultDirectory(), fileManager: FileManager = .default) {
        self.directory = directory
        self.fileManager = fileManager
    }

    /// The configured screenshot location (`com.apple.screencapture` → `location`),
    /// defaulting to the Desktop.
    static func defaultDirectory() -> URL {
        if let location = UserDefaults(suiteName: "com.apple.screencapture")?.string(forKey: "location"),
           !location.isEmpty {
            return URL(fileURLWithPath: (location as NSString).expandingTildeInPath, isDirectory: true)
        }
        return FileManager.default.urls(for: .desktopDirectory, in: .userDomainMask).first
            ?? URL(fileURLWithPath: NSHomeDirectory(), isDirectory: true)
    }

    func start() {
        guard source == nil else { return }
        seen = Set(imageFiles())
        descriptor = open(directory.path, O_EVTONLY)
        guard descriptor >= 0 else {
            Log.shelf.error("Screenshot monitor could not open directory")
            return
        }
        let newSource = DispatchSource.makeFileSystemObjectSource(
            fileDescriptor: descriptor,
            eventMask: .write,
            queue: .global(qos: .utility)
        )
        newSource.setEventHandler { [weak self] in self?.scan() }
        newSource.setCancelHandler { [weak self] in
            if let descriptor = self?.descriptor, descriptor >= 0 { close(descriptor) }
            self?.descriptor = -1
        }
        source = newSource
        newSource.resume()
    }

    func stop() {
        source?.cancel()
        source = nil
    }

    deinit {
        stop()
    }

    private func scan() {
        let current = imageFiles()
        let fresh = current.filter { !seen.contains($0) }
        guard !fresh.isEmpty else { return }
        seen.formUnion(fresh)
        for url in fresh {
            DispatchQueue.main.async { [weak self] in self?.onScreenshot?(url) }
        }
    }

    private func imageFiles() -> [URL] {
        let contents = (try? fileManager.contentsOfDirectory(
            at: directory,
            includingPropertiesForKeys: nil
        )) ?? []
        return contents.filter { Self.imageExtensions.contains($0.pathExtension.lowercased()) }
    }
}
