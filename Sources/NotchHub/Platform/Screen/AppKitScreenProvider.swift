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
            notchSize: hasNotch ? CGSize(width: notchWidth(of: screen), height: notchHeight) : nil
        )
    }

    /// The real notch width: the screen width minus the usable menu-bar areas to
    /// its left and right (`auxiliaryTopLeftArea` / `auxiliaryTopRightArea`).
    private static func notchWidth(of screen: NSScreen) -> CGFloat {
        if let left = screen.auxiliaryTopLeftArea, let right = screen.auxiliaryTopRightArea {
            let width = screen.frame.width - left.width - right.width
            if width > 0 { return width }
        }
        return NotchLayout.collapsed.width
    }
}
