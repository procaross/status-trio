import AppKit
import XCTest
@testable import StatusTrioCore

@MainActor
final class StatusItemInteractionTests: XCTestCase {
    private let anchor = NSRect(x: 320, y: 900, width: 32, height: 24)
    private let panel = NSRect(x: 170, y: 620, width: 364, height: 260)

    func testRapidPhysicalClicksAreNotSwallowedButDuplicateDeliveryIs() {
        var gate = StatusItemClickGate()
        XCTAssertTrue(gate.accept(eventNumber: 100, timestamp: 5))
        XCTAssertFalse(gate.accept(eventNumber: 100, timestamp: 5))
        XCTAssertTrue(gate.accept(eventNumber: 102, timestamp: 5.1))
        XCTAssertTrue(gate.accept(eventNumber: 104, timestamp: 5.2))
    }

    func testMouseDownOnStatusItemDoesNotDismissBeforeMouseUpToggle() {
        let point = NSPoint(x: anchor.midX, y: anchor.midY)
        XCTAssertFalse(PopupDismissalPolicy.shouldDismissOutsideClick(point: point, anchor: anchor, panel: panel))
        XCTAssertTrue(PopupDismissalPolicy.keepOpenOnDeactivation(point: point, pressedButtons: 1, anchor: anchor))
        // A keyboard app switch must still close, even if the cursor was left here.
        XCTAssertFalse(PopupDismissalPolicy.keepOpenOnDeactivation(point: point, pressedButtons: 0, anchor: anchor))
    }

    func testOutsideAndPanelClicksRemainDistinct() {
        XCTAssertFalse(PopupDismissalPolicy.shouldDismissOutsideClick(point: NSPoint(x: 300, y: 700), anchor: anchor, panel: panel))
        XCTAssertTrue(PopupDismissalPolicy.shouldDismissOutsideClick(point: NSPoint(x: 600, y: 700), anchor: anchor, panel: panel))
        XCTAssertTrue(PopupDismissalPolicy.shouldDismissOutsideClick(point: NSPoint(x: 600, y: 700), anchor: nil, panel: nil))
    }

    func testMenuIconAlwaysLeavesFourPointsAboveAndBelow() {
        for height: CGFloat in [22, 24, 32, 37] {
            for requested in [16.0, 28, 36] {
                let size = CompactStatusItemCell.displaySize(requested: requested, barHeight: height)
                XCTAssertLessThanOrEqual(size, height - 8)
                XCTAssertLessThanOrEqual(size, requested)
                XCTAssertGreaterThan(size, 0)
            }
        }
    }

    func testBackdropMaskHasOpaqueCenterAndFeatheredBoundary() throws {
        let mask = FeatheredBackdropView.mask(size: NSSize(width: 364, height: 250))
        let cgImage = try XCTUnwrap(mask.cgImage(forProposedRect: nil, context: nil, hints: nil))
        let bitmap = NSBitmapImageRep(cgImage: cgImage)
        let center = try XCTUnwrap(bitmap.colorAt(x: bitmap.pixelsWide / 2, y: bitmap.pixelsHigh / 2))
        let edge = try XCTUnwrap(bitmap.colorAt(x: 0, y: bitmap.pixelsHigh / 2))
        XCTAssertGreaterThan(center.alphaComponent, 0.95)
        XCTAssertLessThan(edge.alphaComponent, 0.2)
    }
}
