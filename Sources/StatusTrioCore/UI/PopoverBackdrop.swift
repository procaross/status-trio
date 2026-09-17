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
    private var maskScale: CGFloat = 0

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
        maskImage = Self.mask(size: maskSize, scale: scale)
    }

    /// Fade the material itself across 40 points, including the corners. A solid
    /// rounded fill with a blurred shadow still leaves a visible inner contour.
    /// This bitmap is generated at backing resolution only after size/scale changes.
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
                let qx = abs((CGFloat(x) + 0.5) / scale - size.width / 2) - (size.width / 2 - radius)
                let qy = abs((CGFloat(y) + 0.5) / scale - size.height / 2) - (size.height / 2 - radius)
                let distance = hypot(max(qx, 0), max(qy, 0)) + min(max(qx, qy), 0) - radius
                let t = min(1, max(0, (-distance - 2) / 40))
                let alpha = UInt8((t * t * (3 - 2 * t) * 255).rounded())
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
