@testable import NotchHub
import Testing

struct MinimalStatusTests {
    @Test
    func resolveReturnsNilWhenNothingActive() {
        #expect(MinimalStatus.resolve(from: []) == nil)
    }

    @Test
    func resolvePicksHighestPriority() {
        #expect(MinimalStatus.resolve(from: [.mediaPlaying, .upcomingEvent]) == .mediaPlaying)
        #expect(MinimalStatus.resolve(from: [.upcomingEvent, .sharing, .dragging]) == .dragging)
        #expect(
            MinimalStatus.resolve(from: [.mediaPlaying, .aiApprovalWaiting, .dragging]) == .aiApprovalWaiting
        )
    }

    @Test
    func priorityOrderMatchesRequirement() {
        // 要件定義.md §6.2: AI > dragging > sharing > media > upcoming event.
        let ordered = MinimalStatus.allCases.sorted { $0.rawValue < $1.rawValue }
        #expect(ordered == [.aiApprovalWaiting, .dragging, .sharing, .mediaPlaying, .upcomingEvent])
    }
}
