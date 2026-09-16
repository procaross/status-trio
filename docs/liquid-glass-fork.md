# Liquid Glass panel fork

This fork preserves Status Trio's original license and attribution. It changes the popup presentation while retaining the monitoring, localization, configurable section order, keyboard shortcuts, and output switching.

## Design

- On macOS 26+, use a transparent AppKit panel, a behind-window NSVisualEffectView backdrop with a feathered mask, and clear AppKit NSGlassEffectView surfaces. The native effect supplies its own optical edge and shadow; there are no additional painted strokes, bevels, or card shadows. A neutral tint supports white foreground content; the outer window keeps a light appearance. Older systems and Swift 6.1 builds retain NSPopover and system material backgrounds.
- Use 22-point outer padding and 16-point vertical section gaps. Pair adjacent battery and network summaries into 64-point-high capsules while preserving configured section order and visibility. Audio and Bluetooth remain full width. Place the app name, settings, and quit controls in a subdued footer.
- Use native sliders and switches. Audio uses a compact title and control row; its output button reveals or collapses the current-device label and device list, resizing the panel. The output button also exposes the current device in its tooltip. Sound settings are available in the audio card's context menu. Output devices retain their selected checkmark, full tooltip, and accessibility label.
- Keep critical numbers distinct from secondary status text. Follow the selected app locale for numeric formatting. Network tiles open details; location access remains an explicit action where available.
- Settings → panel → Preview panel opens the actual live popup after closing settings. This preview stays open for inspection until Escape or the settings button is used. Normal menu-bar popups remain transient and close on outside clicks or application deactivation.
- Battery/network capsules and icon buttons brighten on hover and compress gently for the duration of a press. Native Button release triggers one action; there is no repeat action or long-press timer. Reduce Motion disables scaling and animation.
- Respect Reduce Transparency with opaque system backgrounds and adaptive foreground colors. Do not add continuous animations, custom rendering loops, private material APIs, or extra monitoring timers.
- Keep the native menu-bar button and accessibility actions, using a compact slot and a circular selection even for wide icon configurations. Selection clears on dismissal and after the context menu closes. The rendered symbol fits the menu bar with at least four points of vertical inset on each side, while retaining the configured clickable slot. Hover tracking does not intercept clicks.
- Status-item mouse-down is excluded from outside-click dismissal and activation dismissal, leaving mouse-up to toggle the panel once. Duplicate delivery of the same event is ignored; separate rapid clicks are accepted. The Dock retains its existing reopen guard.
- The transparent panel stays within the active display and resizes when detail views or output lists change. Temporary key-window changes and attached password sheets do not dismiss it. Reopening the app while its panel is visible preserves that panel; Settings remains available from its gear button.

## Building

Use Xcode 26 or newer for the Liquid Glass appearance:

```sh
swift test
bash scripts/build-app.sh release no-open
```

The app supports macOS 15 and source compatibility with Swift 6.1. An older SDK build uses the older design system even when running on a newer OS. The packaging script records the actual build SDK in LC_BUILD_VERSION before signing rather than letting SwiftPM record the minimum deployment target there.

## Update policy

`StatusTrioUpdatesEnabled` is false in this fork's Info.plist. Both automatic and manual upstream update entry points are disabled, so an upstream Sparkle update cannot replace the custom build. Updates to this fork must be built and installed explicitly. The original bundle identifier is retained for an in-place personal upgrade, preserving preferences and login-item identity. Do not run it alongside the upstream build with the same identifier.

No telemetry, screen capture, private Apple APIs, or new system permissions are introduced.
