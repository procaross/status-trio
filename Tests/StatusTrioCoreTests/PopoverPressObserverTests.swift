import AppKit
import XCTest
@testable import StatusTrioCore

@MainActor
final class PopoverPressObserverTests: XCTestCase {
    func testPressHoldsUntilReleaseAndNeverClaimsHitTesting() throws {
        let (window, view) = fixture()
        var changes: [Bool] = []
        view.onPressChange = { changes.append($0) }
        XCTAssertNil(view.hitTest(NSPoint(x: 100, y: 40)))

        view.observe(try event(.leftMouseDown, in: window, at: NSPoint(x: 100, y: 40)))
        // Holding/dragging must not produce repeating changes or click actions.
        view.observe(try event(.leftMouseDragged, in: window, at: NSPoint(x: 180, y: 40)))
        XCTAssertEqual(changes, [true])
        // Release outside the card still cancels the visual pressed state.
        view.observe(try event(.leftMouseUp, in: window, at: NSPoint(x: 400, y: 200)))
        XCTAssertEqual(changes, [true, false])
        view.removeFromSuperview()
    }

    func testOtherWindowsAndRoundedCornersCannotPressCard() throws {
        let (window, view) = fixture()
        let (otherWindow, otherView) = fixture()
        var changes: [Bool] = []
        view.onPressChange = { changes.append($0) }
        view.observe(try event(.leftMouseDown, in: otherWindow, at: NSPoint(x: 100, y: 40)))
        view.observe(try event(.leftMouseDown, in: window, at: NSPoint(x: 0, y: 0)))
        XCTAssertTrue(changes.isEmpty)
        view.removeFromSuperview()
        otherView.removeFromSuperview()
    }

    func testDeactivationAndRemovalClearHeldState() throws {
        let (window, view) = fixture()
        var changes: [Bool] = []
        view.onPressChange = { changes.append($0) }
        view.observe(try event(.leftMouseDown, in: window, at: NSPoint(x: 100, y: 40)))
        NotificationCenter.default.post(name: NSWindow.didResignKeyNotification, object: window)
        XCTAssertEqual(changes, [true, false])
        view.observe(try event(.leftMouseDown, in: window, at: NSPoint(x: 100, y: 40)))
        view.removeFromSuperview()
        XCTAssertEqual(changes, [true, false, true, false])
    }

    private func fixture() -> (NSWindow, PopoverPressObserverView) {
        let window = NSWindow(contentRect: NSRect(x: 0, y: 0, width: 320, height: 80),
                              styleMask: [.borderless], backing: .buffered, defer: false)
        window.isReleasedWhenClosed = false
        let view = PopoverPressObserverView(frame: NSRect(x: 0, y: 0, width: 320, height: 80))
        window.contentView?.addSubview(view)
        return (window, view)
    }

    private func event(_ type: NSEvent.EventType, in window: NSWindow, at point: NSPoint) throws -> NSEvent {
        try XCTUnwrap(NSEvent.mouseEvent(with: type, location: point, modifierFlags: [], timestamp: 1,
            windowNumber: window.windowNumber, context: nil, eventNumber: 1, clickCount: 1, pressure: 1))
    }
}
