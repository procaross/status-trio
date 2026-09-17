import AppKit
import SwiftUI

/// Blur the live backdrop without painting a material-colored rectangle.
/// The gradient controls diffusion strength, not the opacity of a colored fill.
struct PopoverBackdrop: NSViewRepresentable {
    func makeNSView(context: Context) -> FeatheredBackdropView {
        FeatheredBackdropView()
    }
    func updateNSView(_ view: FeatheredBackdropView, context: Context) {
    }
}

final class FeatheredBackdropView: NSView {
    private let blur: LiveBackdropBlur?
    private var fallback: NSVisualEffectView?
    private(set) var maskImage: NSImage?
    var usesLiveBlur: Bool { blur != nil && fallback == nil }
    private var maskSize = NSSize.zero
    private var maskScale: CGFloat = 0

    init(frame: NSRect = .zero, allowsLiveBlur: Bool = true) {
        blur = allowsLiveBlur ? LiveBackdropBlur() : nil
        super.init(frame: frame)
        wantsLayer = true
        if let blur { layer?.addSublayer(blur.layer) }
        else { installFallback() }
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) is not supported") }
    override func hitTest(_ point: NSPoint) -> NSView? { nil }

    override func viewDidMoveToWindow() {
        super.viewDidMoveToWindow()
        if let window, usesLiveBlur, !LiveBackdropBlur.prepare(window) { installFallback() }
    }

    private func installFallback() {
        guard fallback == nil else { return }
        blur?.layer.removeFromSuperlayer()
        let view = NSVisualEffectView(frame: bounds)
        view.material = .popover
        view.blendingMode = .behindWindow
        view.state = .active
        view.autoresizingMask = [.width, .height]
        view.maskImage = maskImage
        addSubview(view)
        fallback = view
    }

    override func layout() {
        super.layout()
        updateMask()
    }

    override func viewDidChangeBackingProperties() {
        super.viewDidChangeBackingProperties()
        updateMask()
    }

    private func updateMask() {
        let scale = window?.backingScaleFactor ?? 2
        guard bounds.width > 0, bounds.height > 0,
              bounds.size != maskSize || scale != maskScale else { return }
        maskSize = bounds.size
        maskScale = scale
        let mask = Self.mask(size: maskSize, scale: scale)
        maskImage = mask
        if let cgImage = mask.cgImage(forProposedRect: nil, context: nil, hints: nil) {
            blur?.update(frame: bounds, mask: cgImage, scale: scale)
        }
        fallback?.maskImage = mask
    }

    /// Radius ramps from zero at the outer edge to full diffusion inside. The
    /// image is passed to variableBlur.inputMaskImage, NOT CALayer.mask/opacity.
    /// Cache it across hover/press frames and regenerate only for size/scale.
    static func mask(size: NSSize, scale: CGFloat = 2) -> NSImage {
        let width = max(1, Int(ceil(size.width * scale)))
        let height = max(1, Int(ceil(size.height * scale)))
        let bitmap = NSBitmapImageRep(bitmapDataPlanes: nil, pixelsWide: width, pixelsHigh: height,
            bitsPerSample: 8, samplesPerPixel: 4, hasAlpha: true, isPlanar: false,
            colorSpaceName: .deviceRGB, bytesPerRow: width * 4, bitsPerPixel: 32)!
        let pixels = bitmap.bitmapData!
        let radius = min(64, min(size.width, size.height) / 2)
        for y in 0..<height {
            for x in 0..<width {
                let point = CGPoint(x: (CGFloat(x) + 0.5) / scale, y: (CGFloat(y) + 0.5) / scale)
                let qx = abs(point.x - size.width / 2) - (size.width / 2 - radius)
                let qy = abs(point.y - size.height / 2) - (size.height / 2 - radius)
                let distance = hypot(max(qx, 0), max(qy, 0)) + min(max(qx, qy), 0) - radius
                let t = min(1, max(0, (-distance - 2) / 28))
                let opacity = t * t * (3 - 2 * t)
                let alpha = UInt8((opacity * 255).rounded())
                let offset = y * bitmap.bytesPerRow + x * 4
                pixels[offset] = alpha
                pixels[offset + 1] = alpha
                pixels[offset + 2] = alpha
                pixels[offset + 3] = alpha
            }
        }
        bitmap.size = size
        let image = NSImage(size: size)
        image.addRepresentation(bitmap)
        return image
    }
}
