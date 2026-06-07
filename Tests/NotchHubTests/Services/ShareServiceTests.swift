import Foundation
@testable import NotchHub
import Testing

struct ShareServiceTests {
    private struct Harness {
        let service: ShareService
        let presenter: StubSharingPresenter
        let tempWriter: StubTempFileWriter
        let history: StubAirDropHistoryRepository
    }

    private func makeHarness(outcome: ShareOutcome = .sent) -> Harness {
        let presenter = StubSharingPresenter()
        presenter.airDropOutcome = outcome
        let tempWriter = StubTempFileWriter()
        let history = StubAirDropHistoryRepository()
        let service = ShareService(
            sharing: presenter,
            tempFileWriter: tempWriter,
            history: history,
            now: { Date(timeIntervalSince1970: 1_000_000) }
        )
        return Harness(service: service, presenter: presenter, tempWriter: tempWriter, history: history)
    }

    @Test
    func shareFilePresentsURLDirectly() throws {
        let harness = makeHarness()
        try harness.service.share([.fileURL(URL(fileURLWithPath: "/tmp/a.pdf"))])
        #expect(harness.presenter.sharedURLs.first?.first?.path == "/tmp/a.pdf")
        #expect(harness.tempWriter.writtenNames.isEmpty) // no temp file for real files
    }

    @Test
    func shareTextMaterialisesTempFile() throws {
        let harness = makeHarness()
        try harness.service.share([.text("hello world")])
        #expect(harness.tempWriter.writtenNames.contains { $0.hasSuffix(".txt") })
        #expect(harness.presenter.sharedURLs.count == 1)
    }

    @Test
    func shareURLMaterialisesWebloc() throws {
        let harness = makeHarness()
        try harness.service.share([.url(#require(URL(string: "https://example.com")))])
        #expect(harness.tempWriter.writtenNames.contains { $0.hasSuffix(".webloc") })
    }

    @Test
    func airDropRecordsHistoryPerItem() throws {
        let harness = makeHarness(outcome: .sent)
        try harness.service.airDrop([
            .fileURL(URL(fileURLWithPath: "/tmp/a.pdf")),
            .text("note")
        ])
        let records = try harness.history.fetchAll()
        #expect(records.count == 2)
        #expect(records.allSatisfy { $0.outcome == .sent })
        // file keeps its original path; inline text does not.
        #expect(records.contains { $0.originalPath == "/tmp/a.pdf" })
        #expect(records.contains { $0.kind == .text && $0.originalPath == nil })
    }

    @Test
    func airDropRecordsFailureOutcome() throws {
        let harness = makeHarness(outcome: .failed)
        try harness.service.airDrop([.fileURL(URL(fileURLWithPath: "/tmp/a.pdf"))])
        #expect(try harness.history.fetchAll().first?.outcome == .failed)
    }
}
