import AppKit
import QuartzCore

/// Optional compositor-only blur for the locally distributed macOS 26 build.
/// No screenshots, timers, color fills or pixel readback are involved. All SPI
/// access is isolated here and checked before use; the caller supplies a public
/// NSVisualEffectView fallback when a future OS removes these entry points.
@MainActor
final class LiveBackdropBlur {
    let layer: CALayer
    private let filter: NSObject
    static let radius: CGFloat = 6

    init?() {
        guard #available(macOS 26.0, *),
              let layerType = NSClassFromString("CABackdropLayer") as? CALayer.Type,
              let filterType = NSClassFromString("CAFilter") as? NSObject.Type else { return nil }
        let factory = NSSelectorFromString("filterWithType:")
        guard filterType.responds(to: factory),
              let filter = filterType.perform(factory, with: "variableBlur")?.takeUnretainedValue() as? NSObject,
              filter.responds(to: NSSelectorFromString("inputKeys")),
              let inputs = filter.value(forKey: "inputKeys") as? [String],
              Set(["inputRadius", "inputMaskImage", "inputNormalizeEdges"]).isSubset(of: Set(inputs)) else { return nil }
        let layer = layerType.init()
        for setter in ["setWindowServerAware:", "setScale:", "setGroupName:"] {
            guard layer.responds(to: NSSelectorFromString(setter)) else { return nil }
        }
        layer.setValue(true, forKey: "windowServerAware")
        layer.setValue(1.0, forKey: "scale")
        layer.setValue(UUID().uuidString, forKey: "groupName")
        filter.setValue(Self.radius, forKey: "inputRadius")
        filter.setValue(true, forKey: "inputNormalizeEdges")
        // Newer systems expose optional fill controls on variableBlur. Keep
        // them off explicitly, without sending unknown keys to older filters.
        for key in ["inputBlurFillDarkenOpacity", "inputBlurFillLightenOpacity", "inputBlurFillNormalOpacity"]
            where inputs.contains(key) {
            filter.setValue(0.0, forKey: key)
        }
        layer.filters = [filter]
        // Deliberately no material, backgroundColor, tint, opacity or alpha mask.
        // The mask changes the *blur radius*, never the color/opacity of a fill.
        self.layer = layer
        self.filter = filter
    }

    func update(frame: CGRect, mask: CGImage, scale: CGFloat) {
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        layer.frame = frame
        layer.contentsScale = scale
        filter.setValue(mask, forKey: "inputMaskImage")
        CATransaction.commit()
    }

    /// Keep the compositor's live layer tree when the panel loses focus. These
    /// flags only affect our own popup window, never another application's UI.
    static func prepare(_ window: NSWindow) -> Bool {
        let settings = [("setCanHostLayersInWindowServer:", true),
                        ("_setShouldAutoFlattenLayerTree:", false)]
        guard settings.allSatisfy({ window.responds(to: NSSelectorFromString($0.0)) }) else { return false }
        typealias Setter = @convention(c) (AnyObject, Selector, Bool) -> Void
        for (name, value) in settings {
            let selector = NSSelectorFromString(name)
            let setter = unsafeBitCast(window.method(for: selector), to: Setter.self)
            setter(window, selector, value)
        }
        return true
    }
}
