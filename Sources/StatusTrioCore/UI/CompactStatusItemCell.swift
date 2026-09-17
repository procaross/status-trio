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
        min(CGFloat(requested), max(1, barHeight - 2))
    }

    static func slotWidth(iconSize: Double, barHeight: CGFloat) -> CGFloat {
        max(barHeight, displaySize(requested: iconSize, barHeight: barHeight) + 6)
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
        // NSButtonCell adds its own image insets even to borderless image-only
        // cells. Draw the already-sized glyph directly; retain the native button
        // for tracking, actions and accessibility.
        guard let image else { return }
        let scale = min(1, min(cellFrame.width / image.size.width,
                               cellFrame.height / image.size.height))
        let size = NSSize(width: image.size.width * scale, height: image.size.height * scale)
        let rect = NSRect(x: cellFrame.midX - size.width / 2, y: cellFrame.midY - size.height / 2,
                          width: size.width, height: size.height)
        image.draw(in: rect, from: .zero, operation: .sourceOver,
                   fraction: isEnabled ? 1 : 0.5, respectFlipped: true, hints: nil)
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
