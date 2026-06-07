import CoreGraphics

/// Fixture ``ScreenProviding`` for tests and previews.
final class StubScreenProvider: ScreenProviding {
    let screens: [ScreenInfo]
    let main: ScreenInfo

    init(screens: [ScreenInfo], main: ScreenInfo? = nil) {
        precondition(!screens.isEmpty, "StubScreenProvider needs at least one screen")
        self.screens = screens
        self.main = main ?? screens[0]
    }

    /// Single 1440×900 notch-less display at the origin.
    static var singleDefault: StubScreenProvider {
        StubScreenProvider(screens: [
            ScreenInfo(id: 0, frame: CGRect(x: 0, y: 0, width: 1440, height: 900))
        ])
    }

    func screen(containing point: CGPoint) -> ScreenInfo? {
        screens.first { $0.contains(point) }
    }
}
