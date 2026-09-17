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

    func testMenuIconUsesAvailableHeightWithOnePointClearance() {
        for height: CGFloat in [22, 24, 32, 37] {
            for requested in [16.0, 28, 36] {
                let size = CompactStatusItemCell.displaySize(requested: requested, barHeight: height)
                XCTAssertLessThanOrEqual(size, height - 2)
                XCTAssertLessThanOrEqual(size, requested)
                XCTAssertGreaterThan(size, 0)
            }
        }
    }

    func testBlurRadiusMaskHasFullStrengthCenterAndFeatheredBoundary() throws {
        let mask = FeatheredBackdropView.mask(size: NSSize(width: 364, height: 250))
        let cgImage = try XCTUnwrap(mask.cgImage(forProposedRect: nil, context: nil, hints: nil))
        let bitmap = NSBitmapImageRep(cgImage: cgImage)
        let center = try XCTUnwrap(bitmap.colorAt(x: bitmap.pixelsWide / 2, y: bitmap.pixelsHigh / 2))
        let edge = try XCTUnwrap(bitmap.colorAt(x: 0, y: bitmap.pixelsHigh / 2))
        XCTAssertGreaterThan(center.alphaComponent, 0.95)
        XCTAssertLessThan(edge.alphaComponent, 0.2)
    }

    func testBlurRadiusFadesContinuouslyBeforeContentInsetsAtBothScales() throws {
        for scale: CGFloat in [1, 2] {
            let image = FeatheredBackdropView.mask(size: NSSize(width: 384, height: 270), scale: scale)
            let bitmap = NSBitmapImageRep(cgImage: try XCTUnwrap(image.cgImage(forProposedRect: nil, context: nil, hints: nil)))
            func alpha(_ x: Int, _ y: Int) throws -> CGFloat {
                try XCTUnwrap(bitmap.colorAt(x: Int(CGFloat(x) * scale), y: Int(CGFloat(y) * scale))).alphaComponent
            }
            XCTAssertEqual(try alpha(0, 135), 0, accuracy: 0.01)
            XCTAssertLessThan(try alpha(10, 135), 0.3)
            XCTAssertGreaterThan(try alpha(16, 135), 0.45)
            XCTAssertLessThan(try alpha(16, 135), 0.55)
            XCTAssertGreaterThan(try alpha(32, 135), 0.99)
            var previous: CGFloat = 0
            for x in 0...45 {
                let next = try alpha(x, 135)
                XCTAssertGreaterThanOrEqual(next, previous)
                XCTAssertLessThan(next - previous, 0.06, "A sharp contour reappeared at x=\(x)")
                XCTAssertEqual(next, try alpha(192, x), accuracy: 0.01)
                previous = next
            }
            XCTAssertEqual(try alpha(10, 10), 0, accuracy: 0.01)
            XCTAssertGreaterThan(try alpha(36, 36), try alpha(22, 22))
        }
    }

    func testBlurRadiusHasNoHolesOrRingsAtCardBoundaries() throws {
        for scale: CGFloat in [1, 2] {
            let image = FeatheredBackdropView.mask(size: NSSize(width: 384, height: 400), scale: scale)
            let bitmap = NSBitmapImageRep(cgImage: try XCTUnwrap(image.cgImage(forProposedRect: nil, context: nil, hints: nil)))
            // Walk across both top cards and their gap, then down through the
            // audio card and footer. The whole interior must stay diffused.
            for x in 40...344 {
                XCTAssertEqual(try XCTUnwrap(bitmap.colorAt(x: Int(CGFloat(x) * scale), y: Int(70 * scale))).alphaComponent,
                               1, accuracy: 0.01)
            }
            for y in 40...360 {
                XCTAssertEqual(try XCTUnwrap(bitmap.colorAt(x: Int(192 * scale), y: Int(CGFloat(y) * scale))).alphaComponent,
                               1, accuracy: 0.01)
            }
        }
    }

    func testBackdropReusesMaskUntilPanelResizes() throws {
        let view = FeatheredBackdropView(frame: NSRect(x: 0, y: 0, width: 384, height: 262))
        view.layout()
        let original = try XCTUnwrap(view.maskImage)
        for _ in 0..<10 { view.layout() }
        XCTAssertTrue(view.maskImage === original)
        view.setFrameSize(NSSize(width: 384, height: 420))
        view.layout()
        XCTAssertFalse(view.maskImage === original)
        XCTAssertEqual(view.maskImage?.size, view.bounds.size)
    }

    func testStatusCellDrawsReadableGlyphWithoutNativeButtonInsets() throws {
        for height: CGFloat in [22, 24, 32] {
            let size = CompactStatusItemCell.displaySize(requested: 36, barHeight: height)
            let frame = NSRect(x: 0, y: 0, width: size + 6, height: height)
            let cell = CompactStatusItemCell(textCell: "")
            cell.image = StatusIconRenderer.image(snapshot: .placeholder, size: size)
            cell.isEnabled = true
            let bitmap = try XCTUnwrap(NSBitmapImageRep(bitmapDataPlanes: nil,
                pixelsWide: Int(frame.width * 2), pixelsHigh: Int(frame.height * 2),
                bitsPerSample: 8, samplesPerPixel: 4, hasAlpha: true, isPlanar: false,
                colorSpaceName: .deviceRGB, bytesPerRow: 0, bitsPerPixel: 0))
            let context = try XCTUnwrap(NSGraphicsContext(bitmapImageRep: bitmap))
            NSGraphicsContext.saveGraphicsState()
            NSGraphicsContext.current = context
            context.cgContext.scaleBy(x: 2, y: 2)
            cell.draw(withFrame: frame, in: NSView(frame: frame))
            NSGraphicsContext.restoreGraphicsState()
            var minX = bitmap.pixelsWide, minY = bitmap.pixelsHigh, maxX = -1, maxY = -1
            for y in 0..<bitmap.pixelsHigh {
                for x in 0..<bitmap.pixelsWide {
                    guard (bitmap.colorAt(x: x, y: y)?.alphaComponent ?? 0) > 0.1 else { continue }
                    minX = min(minX, x); maxX = max(maxX, x)
                    minY = min(minY, y); maxY = max(maxY, y)
                }
            }
            XCTAssertGreaterThan(CGFloat(maxX - minX + 1) / 2, size * 0.85)
            XCTAssertGreaterThan(CGFloat(maxY - minY + 1) / 2, size * 0.82)
            XCTAssertGreaterThanOrEqual(minY, 1)
            XCTAssertLessThan(maxY, bitmap.pixelsHigh - 1)
            XCTAssertEqual(CGFloat(minX + maxX + 1) / 2, frame.width, accuracy: 1)
        }
    }
}
