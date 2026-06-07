import Foundation
@testable import NotchHub
import Testing

struct AppPathsTests {
    @Test
    func applicationSupportDirectoryEndsWithAppName() throws {
        let url = try AppPaths.applicationSupportDirectory()
        #expect(url.lastPathComponent == "NotchHub")
    }

    @Test
    func databaseURLIsInsideSupportDirectory() throws {
        let support = try AppPaths.applicationSupportDirectory()
        let database = try AppPaths.databaseURL(named: "shelf.db")
        #expect(database.deletingLastPathComponent().path == support.path)
        #expect(database.lastPathComponent == "shelf.db")
    }

    @Test
    func cacheAndThumbnailDirectoriesAreCreated() throws {
        let cache = try AppPaths.cacheDirectory()
        let thumbnails = try AppPaths.thumbnailsDirectory()
        #expect(FileManager.default.fileExists(atPath: cache.path))
        #expect(FileManager.default.fileExists(atPath: thumbnails.path))
        #expect(cache.lastPathComponent == "cache")
        #expect(thumbnails.lastPathComponent == "thumbnails")
    }
}
