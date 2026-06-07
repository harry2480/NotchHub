import Foundation

/// Writes share temp files into a directory (the app cache dir in production, a
/// throwaway dir in tests). Each file gets a unique subfolder so identically
/// named items don't collide.
final class CacheTempFileWriter: TempFileWriting {
    private let directory: URL
    private let fileManager: FileManager

    init(directory: URL, fileManager: FileManager = .default) {
        self.directory = directory
        self.fileManager = fileManager
    }

    /// Uses the app cache directory (`…/NotchHub/cache`).
    static func standard() throws -> CacheTempFileWriter {
        try CacheTempFileWriter(directory: AppPaths.cacheDirectory())
    }

    func writeText(_ text: String, suggestedName: String) throws -> URL {
        try write(data: Data(text.utf8), name: ensureExtension(suggestedName, "txt"))
    }

    func writeMarkdown(_ text: String, suggestedName: String) throws -> URL {
        try write(data: Data(text.utf8), name: ensureExtension(suggestedName, "md"))
    }

    func writeWebloc(_ url: URL, suggestedName: String) throws -> URL {
        let plist: [String: Any] = ["URL": url.absoluteString]
        let data = try PropertyListSerialization.data(fromPropertyList: plist, format: .xml, options: 0)
        return try write(data: data, name: ensureExtension(suggestedName, "webloc"))
    }

    private func write(data: Data, name: String) throws -> URL {
        let folder = directory.appendingPathComponent(UUID().uuidString, isDirectory: true)
        try fileManager.createDirectory(at: folder, withIntermediateDirectories: true)
        let fileURL = folder.appendingPathComponent(name, isDirectory: false)
        try data.write(to: fileURL, options: .atomic)
        return fileURL
    }

    private func ensureExtension(_ name: String, _ ext: String) -> String {
        let base = name.isEmpty ? "Untitled" : name
        return base.lowercased().hasSuffix(".\(ext)") ? base : "\(base).\(ext)"
    }
}
