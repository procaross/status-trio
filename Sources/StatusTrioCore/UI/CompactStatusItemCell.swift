import AppKit

/// Keep the native status button's action and accessibility, but draw a circular
/// selection instead of AppKit's wide automatic status-item capsule.
@MainActor
final class CompactStatusItemCell: NSButtonCell {
    var isPanelVisible = false
    var isHovered = false

    override init(textCell string: String) {
        super.init(textCell: string)
        isBordered = false
        highlightsBy = []
        imageScaling = .scaleProportionallyDown
    }

    required init(coder: NSCoder) { fatalError("init(coder:) is not supported") }

    static func displaySize(requested: Double, barHeight: CGFloat) -> CGFloat {
        min(CGFloat(requested), max(1, barHeight - 8))
    }

    static func slotWidth(iconSize: Double, barHeight: CGFloat) -> CGFloat {
        max(barHeight, CGFloat(iconSize) + 4)
    }

    static func selectionRect(in frame: NSRect) -> NSRect {
        let diameter = max(0, min(frame.width, frame.height) - 4)
        return NSRect(x: frame.midX - diameter / 2, y: frame.midY - diameter / 2,
                      width: diameter, height: diameter)
    }

    override func draw(withFrame cellFrame: NSRect, in controlView: NSView) {
        if isPanelVisible || isHighlighted || isHovered {
            NSColor.white.withAlphaComponent(isHighlighted ? 0.28 : (isPanelVisible ? 0.20 : 0.10)).setFill()
            NSBezierPath(ovalIn: Self.selectionRect(in: cellFrame)).fill()
        }
        super.draw(withFrame: cellFrame, in: controlView)
    }
}

/// A transparent tracking view preserves the native status button's hit testing.
@MainActor
final class StatusItemHoverView: NSView {
    private var hoverTracking: NSTrackingArea?
    override func hitTest(_ point: NSPoint) -> NSView? { nil }
    override func updateTrackingAreas() {
        super.updateTrackingAreas()
        if let hoverTracking { removeTrackingArea(hoverTracking) }
        let area = NSTrackingArea(rect: .zero, options: [.mouseEnteredAndExited, .activeAlways, .inVisibleRect], owner: self)
        addTrackingArea(area)
        hoverTracking = area
    }
    override func mouseEntered(with event: NSEvent) { setHovered(true) }
    override func mouseExited(with event: NSEvent) { setHovered(false) }
    private func setHovered(_ hovered: Bool) {
        guard let button = superview as? NSStatusBarButton,
              let cell = button.cell as? CompactStatusItemCell else { return }
        cell.isHovered = hovered
        button.needsDisplay = true
    }
}
