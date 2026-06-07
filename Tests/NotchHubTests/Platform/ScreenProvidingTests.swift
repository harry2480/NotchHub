import CoreGraphics
@testable import NotchHub
import Testing

struct ScreenProvidingTests {
    private func screen(_ id: Int, hasNotch: Bool) -> ScreenInfo {
        ScreenInfo(
            id: id,
            frame: CGRect(x: 0, y: 0, width: 1512, height: 982),
            hasNotch: hasNotch,
            notchSize: hasNotch ? CGSize(width: 210, height: 37) : nil
        )
    }

    @Test
    func preferredScreenPicksNotchDisplayEvenWhenNotMain() {
        // External (no notch) is main; built-in has the notch.
        let external = screen(0, hasNotch: false)
        let builtIn = screen(1, hasNotch: true)
        let provider = StubScreenProvider(screens: [external, builtIn], main: external)
        #expect(provider.preferredScreen.id == builtIn.id)
    }

    @Test
    func preferredScreenFallsBackToMainWithoutNotch() {
        let external = screen(0, hasNotch: false)
        let secondary = screen(1, hasNotch: false)
        let provider = StubScreenProvider(screens: [external, secondary], main: secondary)
        #expect(provider.preferredScreen.id == secondary.id)
    }
}
