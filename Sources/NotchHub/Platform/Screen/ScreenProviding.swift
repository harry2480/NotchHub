import CoreGraphics

/// Supplies display geometry for multi-display notch placement
/// (要件定義.md §19.2). Hides `NSScreen` behind a protocol so geometry logic and
/// view models can be tested with fixtures.
protocol ScreenProviding {
    var screens: [ScreenInfo] { get }
    /// The display that hosts the menu bar / notch by default.
    var main: ScreenInfo { get }
    /// The display containing `point`, if any.
    func screen(containing point: CGPoint) -> ScreenInfo?
}
