import AppKit

/// Deduplicate a delivered mouse event, never a second physical click.
struct StatusItemClickGate {
    private var lastEvent: Int?
    private var lastTimestamp: TimeInterval?

    mutating func accept(eventNumber: Int, timestamp: TimeInterval) -> Bool {
        guard lastEvent != eventNumber || lastTimestamp != timestamp else { return false }
        lastEvent = eventNumber
        lastTimestamp = timestamp
        return true
    }
}

enum PopupDismissalPolicy {
    static func isAnchorClick(point: NSPoint, anchor: NSRect?) -> Bool {
        guard let anchor else { return false }
        return anchor.contains(point)
    }

    static func shouldDismissOutsideClick(point: NSPoint, anchor: NSRect?, panel: NSRect?) -> Bool {
        !isAnchorClick(point: point, anchor: anchor) && !(panel?.contains(point) ?? false)
    }

    static func keepOpenOnDeactivation(point: NSPoint, pressedButtons: Int, anchor: NSRect?) -> Bool {
        pressedButtons != 0 && isAnchorClick(point: point, anchor: anchor)
    }
}
