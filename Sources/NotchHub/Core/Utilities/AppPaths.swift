import Foundation

/// Resolves the on-disk locations NotchHub uses under
/// `~/Library/Application Support/NotchHub/` (see インフラストラクチャ規約.md).
///
/// NotchHub is a fully local app, so every path is rooted in the user's
/// Application Support directory. Directory creation is performed lazily so the
/// folders only appear the first time they are needed.
enum AppPaths {
    static let appName = "NotchHub"

    /// `~/Library/Application Support/NotchHub/`, created if absent.
    static func applicationSupportDirectory(fileManager: FileManager = .default) throws -> URL {
        let base = try fileManager.url(
            for: .applicationSupportDirectory,
            in: .userDomainMask,
            appropriateFor: nil,
            create: true
        )
        let directory = base.appendingPathComponent(appName, isDirectory: true)
        try fileManager.createDirectory(at: directory, withIntermediateDirectories: true)
        return directory
    }

    /// Absolute path to a SQLite database file under the support directory.
    static func databaseURL(named name: String, fileManager: FileManager = .default) throws -> URL {
        try applicationSupportDirectory(fileManager: fileManager).appendingPathComponent(name, isDirectory: false)
    }

    /// `~/Library/Application Support/NotchHub/cache/`, created if absent.
    static func cacheDirectory(fileManager: FileManager = .default) throws -> URL {
        try subdirectory("cache", fileManager: fileManager)
    }

    /// `~/Library/Application Support/NotchHub/thumbnails/`, created if absent.
    static func thumbnailsDirectory(fileManager: FileManager = .default) throws -> URL {
        try subdirectory("thumbnails", fileManager: fileManager)
    }

    private static func subdirectory(_ name: String, fileManager: FileManager) throws -> URL {
        let directory = try applicationSupportDirectory(fileManager: fileManager)
            .appendingPathComponent(name, isDirectory: true)
        try fileManager.createDirectory(at: directory, withIntermediateDirectories: true)
        return directory
    }
}
