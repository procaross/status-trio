import AppKit
import SwiftUI

/// Sample windows behind the panel, with a soft alpha boundary rather than a
/// solid rounded SwiftUI fill. The mask is rebuilt only when layout size changes.
struct PopoverBackdrop: NSViewRepresentable {
    var glassRegions: [CGRect] = []

    func makeNSView(context: Context) -> FeatheredBackdropView {
        let view = FeatheredBackdropView()
        view.material = .underWindowBackground
        view.blendingMode = .behindWindow
        view.state = .active
        view.glassRegions = glassRegions
        return view
    }
    func updateNSView(_ view: FeatheredBackdropView, context: Context) {
        view.glassRegions = glassRegions
    }
}

final class FeatheredBackdropView: NSVisualEffectView {
    private var maskSize = NSSize.zero
    private var maskScale: CGFloat = 0
    private var maskedRegions: [CGRect] = []
    var glassRegions: [CGRect] = [] {
        didSet {
            if oldValue != glassRegions { needsLayout = true }
        }
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
              bounds.size != maskSize || scale != maskScale || regionsNeedNewMask else { return }
        maskSize = bounds.size
        maskScale = scale
        maskedRegions = glassRegions
        maskImage = Self.mask(size: maskSize, scale: scale, glassRegions: glassRegions)
    }

    private var regionsNeedNewMask: Bool {
        guard glassRegions.count == maskedRegions.count else { return true }
        // Hover/press scale changes fit within the ten-point feather. Keep the
        // bitmap stable during those animations instead of rebuilding every frame.
        return zip(glassRegions, maskedRegions).contains { current, previous in
            abs(current.minX - previous.minX) > 4 || abs(current.maxX - previous.maxX) > 4 ||
            abs(current.minY - previous.minY) > 4 || abs(current.maxY - previous.maxY) > 4
        }
    }

    /// Fade the material itself across 40 points, including the corners. A solid
    /// rounded fill with a blurred shadow still leaves a visible inner contour.
    /// This bitmap is generated at backing resolution only after size/scale changes.
    static func mask(size: NSSize, scale: CGFloat = 2, glassRegions: [CGRect] = []) -> NSImage {
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
                let t = min(1, max(0, (-distance - 2) / 40))
                var opacity = t * t * (3 - 2 * t)
                // Native glass must sample the actual backdrop, not a second
                // material that has already flattened its contrast and colors.
                for region in glassRegions {
                    guard region.insetBy(dx: -8, dy: -8).contains(point) else { continue }
                    let corner = min(32, min(region.width, region.height) / 2)
                    let dx = abs(point.x - region.midX) - (region.width / 2 - corner)
                    let dy = abs(point.y - region.midY) - (region.height / 2 - corner)
                    let distance = hypot(max(dx, 0), max(dy, 0)) + min(max(dx, dy), 0) - corner
                    let edge = min(1, max(0, (distance + 2) / 10))
                    opacity *= edge * edge * (3 - 2 * edge)
                }
                let alpha = UInt8((opacity * 255).rounded())
                let offset = y * bitmap.bytesPerRow + x * 4
                pixels[offset] = 255
                pixels[offset + 1] = 255
                pixels[offset + 2] = 255
                pixels[offset + 3] = alpha
            }
        }
        bitmap.size = size
        let image = NSImage(size: size)
        image.addRepresentation(bitmap)
        return image
    }
}
