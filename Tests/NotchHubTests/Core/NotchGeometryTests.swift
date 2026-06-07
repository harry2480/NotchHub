import CoreGraphics
@testable import NotchHub
import Testing

struct NotchGeometryTests {
    private let screen = ScreenInfo(id: 0, frame: CGRect(x: 0, y: 0, width: 1440, height: 900))

    @Test
    func frameIsTopCentredForEachMode() {
        for mode in NotchMode.allCases {
            let frame = NotchGeometry.frame(for: mode, on: screen)
            let size = NotchLayout.size(for: mode)
            #expect(frame.size == size)
            #expect(frame.midX == screen.frame.midX)
            #expect(frame.maxY == screen.frame.maxY) // hugs the top edge
        }
    }

    @Test
    func collapsedHugsTheRealNotchOnNotchDisplays() {
        let notchSize = CGSize(width: 210, height: 37)
        let notched = ScreenInfo(
            id: 2,
            frame: CGRect(x: 0, y: 0, width: 1512, height: 982),
            hasNotch: true,
            notchSize: notchSize
        )
        let collapsed = NotchGeometry.frame(for: .collapsed, on: notched)
        // Real notch width; height extends below the cutout for a click target.
        #expect(collapsed.width == notchSize.width)
        #expect(collapsed.height == notchSize.height + NotchLayout.notchClickMargin)
        #expect(collapsed.midX == notched.frame.midX)
        #expect(collapsed.maxY == notched.frame.maxY)
        // Expansion uses the content-panel size and sits BELOW the notch so its
        // content is not hidden by the cutout.
        let expanded = NotchGeometry.frame(for: .expanded, on: notched)
        #expect(expanded.size == NotchLayout.expanded)
        #expect(expanded.maxY == notched.frame.maxY - notchSize.height)
    }

    @Test
    func frameRespectsOffsetScreenOrigin() {
        let external = ScreenInfo(id: 1, frame: CGRect(x: 1440, y: 0, width: 1920, height: 1080))
        let frame = NotchGeometry.frame(for: .collapsed, on: external)
        #expect(frame.midX == external.frame.midX)
        #expect(frame.maxY == external.frame.maxY)
    }

    @Test
    func isApproachingTrueNearTopCentre() {
        #expect(NotchGeometry.isApproaching(CGPoint(x: 720, y: 895), on: screen))
        #expect(NotchGeometry.isApproaching(CGPoint(x: 720, y: 900), on: screen))
    }

    @Test
    func isApproachingFalseAwayFromNotch() {
        #expect(!NotchGeometry.isApproaching(CGPoint(x: 720, y: 700), on: screen)) // too low
        #expect(!NotchGeometry.isApproaching(CGPoint(x: 50, y: 898), on: screen)) // far left
        #expect(!NotchGeometry.isApproaching(CGPoint(x: 720, y: 920), on: screen)) // above screen
    }
}
