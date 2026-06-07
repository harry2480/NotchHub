import Foundation
@testable import NotchHub
import Testing

struct CacheTempFileWriterTests {
    private func makeWriter() throws -> (CacheTempFileWriter, URL) {
        let dir = FileManager.default.temporaryDirectory
            .appendingPathComponent("notchhub-tests-\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return (CacheTempFileWriter(directory: dir), dir)
    }

    @Test
    func writesTextFileWithContent() throws {
        let (writer, dir) = try makeWriter()
        defer { try? FileManager.default.removeItem(at: dir) }
        let url = try writer.writeText("hello", suggestedName: "note")
        #expect(url.pathExtension == "txt")
        #expect(try String(contentsOf: url, encoding: .utf8) == "hello")
    }

    @Test
    func writesMarkdownExtension() throws {
        let (writer, dir) = try makeWriter()
        defer { try? FileManager.default.removeItem(at: dir) }
        let url = try writer.writeMarkdown("# Title", suggestedName: "doc")
        #expect(url.pathExtension == "md")
    }

    @Test
    func writesWeblocContainingURL() throws {
        let (writer, dir) = try makeWriter()
        defer { try? FileManager.default.removeItem(at: dir) }
        let url = try writer.writeWebloc(#require(URL(string: "https://example.com")), suggestedName: "link")
        #expect(url.pathExtension == "webloc")
        let data = try Data(contentsOf: url)
        let plist = try PropertyListSerialization.propertyList(from: data, options: [], format: nil)
        let dict = try #require(plist as? [String: Any])
        #expect(dict["URL"] as? String == "https://example.com")
    }

    @Test
    func doesNotDoubleExtension() throws {
        let (writer, dir) = try makeWriter()
        defer { try? FileManager.default.removeItem(at: dir) }
        let url = try writer.writeText("x", suggestedName: "already.txt")
        #expect(url.lastPathComponent == "already.txt")
    }
}
