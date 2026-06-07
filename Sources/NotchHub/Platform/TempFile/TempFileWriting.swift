import Foundation

/// Writes inline text/URL content to temporary files for sharing
/// (要件定義.md §8.5: 共有時のみ .txt / .md / .webloc を生成).
protocol TempFileWriting {
    func writeText(_ text: String, suggestedName: String) throws -> URL
    func writeMarkdown(_ text: String, suggestedName: String) throws -> URL
    func writeWebloc(_ url: URL, suggestedName: String) throws -> URL
}
