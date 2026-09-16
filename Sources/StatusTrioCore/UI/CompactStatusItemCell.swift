import AppKit

/// Keep the native status button's action and accessibility, but draw a circular
/// selection instead of AppKit's wide automatic status-item capsule.
@MainActor
final class CompactStatusItemCell: NSButtonCell {
    var isPanelVisible = false

    override init(textCell string: String) {
        super.init(textCell: string)
        isBordered = false
        highlightsBy = []
        imageScaling = .scaleProportionallyDown
    }

    required init(coder: NSCoder) { fatalError("init(coder:) is not supported") }

    static func slotWidth(iconSize: Double, barHeight: CGFloat) -> CGFloat {
        max(barHeight, CGFloat(iconSize) + 4)
    }

    static func selectionRect(in frame: NSRect) -> NSRect {
        let diameter = max(0, min(frame.width, frame.height) - 2)
        return NSRect(x: frame.midX - diameter / 2, y: frame.midY - diameter / 2,
                      width: diameter, height: diameter)
    }

    override func draw(withFrame cellFrame: NSRect, in controlView: NSView) {
        if isPanelVisible || isHighlighted {
            NSColor.white.withAlphaComponent(0.20).setFill()
            NSBezierPath(ovalIn: Self.selectionRect(in: cellFrame)).fill()
        }
        super.draw(withFrame: cellFrame, in: controlView)
    }
}
