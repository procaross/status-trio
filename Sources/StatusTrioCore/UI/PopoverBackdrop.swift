import AppKit
import SwiftUI

/// Sample windows behind the panel, with a soft alpha boundary rather than a
/// solid rounded SwiftUI fill. The mask is rebuilt only when layout size changes.
struct PopoverBackdrop: NSViewRepresentable {
    func makeNSView(context: Context) -> FeatheredBackdropView {
        let view = FeatheredBackdropView()
        view.material = .popover
        view.blendingMode = .behindWindow
        view.state = .active
        return view
    }
    func updateNSView(_ view: FeatheredBackdropView, context: Context) {}
}

final class FeatheredBackdropView: NSVisualEffectView {
    private var maskSize = NSSize.zero
    override func layout() {
        super.layout()
        guard bounds.size != maskSize, bounds.width > 0, bounds.height > 0 else { return }
        maskSize = bounds.size
        maskImage = Self.mask(size: maskSize)
    }

    static func mask(size: NSSize) -> NSImage {
        NSImage(size: size, flipped: false) { rect in
            NSGraphicsContext.saveGraphicsState()
            let shadow = NSShadow()
            shadow.shadowColor = NSColor.white
            shadow.shadowBlurRadius = 14
            shadow.shadowOffset = .zero
            shadow.set()
            NSColor.white.setFill()
            NSBezierPath(roundedRect: rect.insetBy(dx: 10, dy: 10), xRadius: 32, yRadius: 32).fill()
            NSGraphicsContext.restoreGraphicsState()
            return true
        }
    }
}
