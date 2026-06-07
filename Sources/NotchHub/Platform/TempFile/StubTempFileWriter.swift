import Foundation

/// Test/preview ``TempFileWriting`` that returns synthetic URLs without touching
/// the file system, recording each request.
final class StubTempFileWriter: TempFileWriting {
    private(set) var writtenNames: [String] = []

    func writeText(_: String, suggestedName: String) throws -> URL {
        record(suggestedName, "txt")
    }

    func writeMarkdown(_: String, suggestedName: String) throws -> URL {
        record(suggestedName, "md")
    }

    func writeWebloc(_: URL, suggestedName: String) throws -> URL {
        record(suggestedName, "webloc")
    }

    private func record(_ name: String, _ ext: String) -> URL {
        let fileName = "\(name).\(ext)"
        writtenNames.append(fileName)
        return URL(fileURLWithPath: "/tmp/notchhub-stub/\(UUID().uuidString)/\(fileName)")
    }
}
