import AppKit
import XCTest
@testable import StatusTrioCore

@MainActor
final class StatusPopupPresentationTests: XCTestCase {
    func testSelectionStaysCircularInWideMenuSlots() {
        for frame in [NSRect(x: 0, y: 0, width: 48, height: 24),
                      NSRect(x: 12, y: 8, width: 40, height: 32),
                      NSRect(x: 0, y: 0, width: 22, height: 37)] {
            let selection = CompactStatusItemCell.selectionRect(in: frame)
            XCTAssertEqual(selection.width, selection.height)
            XCTAssertEqual(selection.midX, frame.midX)
            XCTAssertEqual(selection.midY, frame.midY)
            XCTAssertTrue(frame.contains(selection))
        }
    }

    func testIconSlotKeepsSmallIconsClickableAndLargeIconsUnclipped() {
        for height: CGFloat in [22, 24, 32] {
            for size in [16.0, 28.0, 36.0] {
                let displayed = CompactStatusItemCell.displaySize(requested: size, barHeight: height)
                let width = CompactStatusItemCell.slotWidth(iconSize: size, barHeight: height)
                XCTAssertGreaterThanOrEqual(width, height)
                XCTAssertGreaterThanOrEqual(width - displayed, 4)
                XCTAssertLessThanOrEqual(width, max(height, displayed + 8))
            }
        }
    }

    func testPanelFitsScreenCornersAndDockEdges() {
        // A secondary display may have a negative origin.
        let visible = NSRect(x: -1920, y: 25, width: 1908, height: 1020)
        for anchor in [NSRect(x: -1900, y: 1045, width: 28, height: 24),
                       NSRect(x: -40, y: 1045, width: 28, height: 24),
                       NSRect(x: -980, y: 0, width: 1, height: 1)] {
            for edge in [NSRectEdge.minY, .maxY, .minX, .maxX] {
                let frame = StatusPopupPresenter.frame(size: NSSize(width: 348, height: 560),
                    anchor: anchor, available: visible, edge: edge)
                XCTAssertTrue(visible.contains(frame))
                XCTAssertEqual(frame.size, NSSize(width: 348, height: 560))
            }
        }
    }

    func testTallPanelRemainsWithinSmallDisplay() {
        let visible = NSRect(x: 0, y: 0, width: 320, height: 480)
        let frame = StatusPopupPresenter.frame(size: NSSize(width: 348, height: 900),
            anchor: NSRect(x: 200, y: 480, width: 28, height: 24), available: visible, edge: .minY)
        XCTAssertEqual(frame, visible)
    }

    func testGlassPanelResizesWithContentAndClosesOnce() async throws {
        guard StatusPopupPresenter.usesGlassPanel else { throw XCTSkip("Modern glass panel only") }
        _ = NSApplication.shared
        let presenter = StatusPopupPresenter()
        let content = NSViewController()
        content.view = NSView(frame: NSRect(x: 0, y: 0, width: 348, height: 180))
        content.preferredContentSize = NSSize(width: 348, height: 180)
        presenter.contentViewController = content
        let anchor = NSWindow(contentRect: NSRect(x: 300, y: 500, width: 1, height: 1),
            styleMask: .borderless, backing: .buffered, defer: false)
        anchor.contentView = NSView(frame: NSRect(x: 0, y: 0, width: 1, height: 1))
        var closeCount = 0
        presenter.onClose = { closeCount += 1 }
        presenter.show(relativeTo: .zero, of: anchor.contentView!, preferredEdge: .minY)
        defer { presenter.performClose(nil) }
        XCTAssertTrue(presenter.isShown)
        XCTAssertEqual(content.view.window?.frame.height, 180)
        content.preferredContentSize = NSSize(width: 348, height: 300)
        let deadline = ContinuousClock.now.advanced(by: .seconds(2))
        while content.view.window?.frame.height != 300 && ContinuousClock.now < deadline {
            try await Task.sleep(for: .milliseconds(10))
        }
        XCTAssertEqual(content.view.window?.frame.height, 300)
        presenter.performClose(nil)
        presenter.performClose(nil)
        XCTAssertFalse(presenter.isShown)
        XCTAssertEqual(closeCount, 1)
    }
}
