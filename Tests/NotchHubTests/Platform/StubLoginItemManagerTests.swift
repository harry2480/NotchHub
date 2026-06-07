@testable import NotchHub
import Testing

struct StubLoginItemManagerTests {
    @Test
    func defaultsToDisabled() {
        #expect(StubLoginItemManager().isEnabled == false)
    }

    @Test
    func enableAndDisableToggleState() throws {
        let manager = StubLoginItemManager()
        try manager.enable()
        #expect(manager.isEnabled)
        try manager.disable()
        #expect(manager.isEnabled == false)
    }

    @Test
    func initialStateIsRespected() {
        #expect(StubLoginItemManager(isEnabled: true).isEnabled)
    }
}
