import AppKit
import XCTest
@testable import StatusTrioCore

@MainActor
final class LiveBackdropBlurTests: XCTestCase {
    func testLiveBackdropUsesOnlyBlurAndNeverAColorOrOpacityMask() throws {
        guard #available(macOS 26.0, *) else { throw XCTSkip("Compositor blur uses the modern panel") }
        let blur = try XCTUnwrap(LiveBackdropBlur())
        XCTAssertNil(blur.layer.backgroundColor)
        XCTAssertNil(blur.layer.contents)
        XCTAssertNil(blur.layer.mask)
        XCTAssertEqual(blur.layer.opacity, 1)
        let filters = try XCTUnwrap(blur.layer.filters as? [NSObject])
        XCTAssertEqual(filters.count, 1)
        XCTAssertEqual(filters[0].value(forKey: "inputRadius") as? CGFloat, 6)
        XCTAssertEqual(blur.layer.value(forKey: "windowServerAware") as? Bool, true)
    }

    func testLayoutSuppliesRadiusMapWithoutAddingAnOpacityMask() throws {
        guard #available(macOS 26.0, *) else { throw XCTSkip("Compositor blur uses the modern panel") }
        let blur = try XCTUnwrap(LiveBackdropBlur())
        let image = FeatheredBackdropView.mask(size: NSSize(width: 384, height: 262))
        let mask = try XCTUnwrap(image.cgImage(forProposedRect: nil, context: nil, hints: nil))
        blur.update(frame: CGRect(x: 0, y: 0, width: 384, height: 262), mask: mask, scale: 2)
        XCTAssertEqual(blur.layer.frame.size, NSSize(width: 384, height: 262))
        XCTAssertNil(blur.layer.mask)
        let filter = try XCTUnwrap(blur.layer.filters?.first as? NSObject)
        XCTAssertNotNil(filter.value(forKey: "inputMaskImage"))
        XCTAssertNil(blur.layer.backgroundColor)
    }

    func testUnsupportedRendererFallsBackToPublicMaterialWithoutBlockingClicks() {
        let view = FeatheredBackdropView(frame: NSRect(x: 0, y: 0, width: 384, height: 262), allowsLiveBlur: false)
        view.layout()
        XCTAssertFalse(view.usesLiveBlur)
        XCTAssertEqual(view.subviews.count, 1)
        let fallback = view.subviews.first as? NSVisualEffectView
        XCTAssertEqual(fallback?.blendingMode, .behindWindow)
        XCTAssertEqual(fallback?.state, .active)
        XCTAssertNotNil(fallback?.maskImage)
        XCTAssertNil(view.hitTest(NSPoint(x: 100, y: 100)))
    }
}
