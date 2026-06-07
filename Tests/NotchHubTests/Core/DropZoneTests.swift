import CoreGraphics
@testable import NotchHub
import Testing

struct DropZoneTests {
    private let frame = CGRect(x: 0, y: 0, width: 300, height: 120)

    @Test
    func centreOfEachColumnHitsItsZone() {
        let layout = DragZoneLayout(frame: frame)
        for zone in DropZone.allCases {
            let centre = CGPoint(x: layout.rect(for: zone).midX, y: layout.rect(for: zone).midY)
            #expect(layout.zone(at: centre) == zone)
        }
    }

    @Test
    func deadZoneBetweenColumnsReturnsNil() {
        let layout = DragZoneLayout(frame: frame)
        // The boundary between the left (shelf) and centre (share) columns sits
        // at x = 100; with a dead-zone margin neither active rect covers it.
        #expect(layout.zone(at: CGPoint(x: 100, y: 60)) == nil)
    }

    @Test
    func pointOutsideFrameReturnsNil() {
        let layout = DragZoneLayout(frame: frame)
        #expect(layout.zone(at: CGPoint(x: -10, y: 60)) == nil)
        #expect(layout.zone(at: CGPoint(x: 150, y: 200)) == nil)
    }

    @Test
    func zoneRectsStayWithinFrame() {
        let layout = DragZoneLayout(frame: frame)
        for zone in DropZone.allCases {
            #expect(frame.contains(layout.rect(for: zone)))
        }
    }

    @Test
    func zoneOrderIsLeftToRight() {
        let layout = DragZoneLayout(frame: frame)
        #expect(layout.rect(for: .shelf).midX < layout.rect(for: .share).midX)
        #expect(layout.rect(for: .share).midX < layout.rect(for: .airDrop).midX)
    }
}
