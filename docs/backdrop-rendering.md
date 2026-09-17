# Popup backdrop rendering

The modern popup uses a live compositor blur instead of a translucent material fill. `CABackdropLayer` runs one `CAFilter` of type `variableBlur`. Its mask controls blur strength (zero at the edge, six points inside); it is not a layer opacity mask and does not paint any color. The native glass controls above it retain their own tint, refractive edge and interaction feedback.

The renderer does not capture screenshots, read pixels, poll windows or upload display content. Mask generation is cached by popup size and backing scale. The layer is only attached to the application's own popup; its window keeps the compositing layer tree live when focus changes.

## Compatibility

`CABackdropLayer`, `CAFilter`, and the layer-hosting window setters are private macOS interfaces. They are runtime-checked and isolated in `LiveBackdropBlur.swift`. This path is only used on macOS 26 and newer. Missing classes, filter inputs or window setters select the public `NSVisualEffectView` fallback. Reduce Transparency keeps the existing opaque accessibility surface.

Private interfaces can change with an OS update and are unsuitable for Mac App Store distribution. The fallback preserves functionality but cannot promise the same appearance. A successful test suite establishes runtime configuration and fallback behavior, not visual equivalence to Control Center.

## Verification

Use a small same-window fixture with large black text, separated blue/red blocks and empty white space. Pure blur should soften the text and spread the colored blocks while leaving the empty white area unchanged. Also inspect the installed popup over another application's content: isolated window captures cannot establish cross-window sampling quality. Check collapsed and expanded audio, focus changes and dismissal; leave system volume unchanged.

Implementation references:

- [Core Animation backdrop blur wrapper](https://github.com/kageroumado/core-animation-private/blob/main/Sources/CoreAnimationPrivate/CABackdropLayer%2BBlur.swift)
- [Variable blur filter and radius mask](https://github.com/aheze/VariableBlurView/blob/main/Sources/VariableBlurView.swift)
