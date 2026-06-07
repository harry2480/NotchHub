import AppKit

/// Production ``ScreenProviding`` backed by `NSScreen`.
final class AppKitScreenProvider: ScreenProviding {
    var screens: [ScreenInfo] {
        NSScreen.screens.enumerated().map { index, screen in
            Self.info(for: screen, id: index)
        }
    }

    var main: ScreenInfo {
        if let main = NSScreen.main,
           let index = NSScreen.screens.firstIndex(of: main) {
            return Self.info(for: main, id: index)
        }
        return screens.first ?? ScreenInfo(id: 0, frame: .zero)
    }

    func screen(containing point: CGPoint) -> ScreenInfo? {
        screens.first { $0.contains(point) }
    }

    private static func info(for screen: NSScreen, id: Int) -> ScreenInfo {
        let notchHeight = screen.safeAreaInsets.top
        let hasNotch = notchHeight > 0
        return ScreenInfo(
            id: id,
            frame: screen.frame,
            hasNotch: hasNotch,
            notchSize: hasNotch ? CGSize(width: NotchLayout.collapsed.width, height: notchHeight) : nil
        )
    }
}
