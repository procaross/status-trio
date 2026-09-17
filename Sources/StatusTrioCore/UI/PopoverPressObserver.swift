import AppKit
import SwiftUI

struct PopoverPressObserver: NSViewRepresentable {
    @Binding var isPressed: Bool

    func makeNSView(context: Context) -> PopoverPressObserverView {
        let view = PopoverPressObserverView()
        view.onPressChange = { isPressed = $0 }
        return view
    }

    func updateNSView(_ view: PopoverPressObserverView, context: Context) {
        view.onPressChange = { isPressed = $0 }
    }

    static func dismantleNSView(_ view: PopoverPressObserverView, coordinator: ()) {
        view.stopObserving()
    }
}

/// A passive, window-scoped observer. Returning every event unchanged preserves
/// native slider tracking, context menus and the single action on button release.
final class PopoverPressObserverView: NSView {
    var onPressChange: ((Bool) -> Void)?
    private var pressed = false
    // AppKit installs/removes the monitor on the main thread. Nonisolated access
    // is only for teardown, keeping the Swift 6.1 toolchain supported.
    nonisolated(unsafe) private var eventMonitor: Any?

    override func hitTest(_ point: NSPoint) -> NSView? { nil }

    override func viewDidMoveToWindow() {
        super.viewDidMoveToWindow()
        stopObserving()
        guard let window else { return }
        eventMonitor = NSEvent.addLocalMonitorForEvents(matching: [.leftMouseDown, .leftMouseUp]) { [weak self] event in
            MainActor.assumeIsolated { self?.observe(event) }
            return event
        }
        NotificationCenter.default.addObserver(self, selector: #selector(cancelPress),
            name: NSWindow.didResignKeyNotification, object: window)
        NotificationCenter.default.addObserver(self, selector: #selector(cancelPress),
            name: NSWindow.willCloseNotification, object: window)
    }

    func observe(_ event: NSEvent) {
        if event.type == .leftMouseUp {
            setPressed(false)
        } else if event.type == .leftMouseDown {
            let shape = NSBezierPath(roundedRect: bounds, xRadius: 32, yRadius: 32)
            setPressed(event.window === window && window != nil &&
                shape.contains(convert(event.locationInWindow, from: nil)))
        }
    }

    func stopObserving() {
        if let eventMonitor { NSEvent.removeMonitor(eventMonitor) }
        eventMonitor = nil
        NotificationCenter.default.removeObserver(self)
        cancelPress()
    }

    @objc private func cancelPress() { setPressed(false) }

    private func setPressed(_ value: Bool) {
        guard pressed != value else { return }
        pressed = value
        onPressChange?(value)
    }

    deinit {
        if let eventMonitor { NSEvent.removeMonitor(eventMonitor) }
        NotificationCenter.default.removeObserver(self)
    }
}
