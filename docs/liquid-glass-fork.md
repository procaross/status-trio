# Liquid Glass panel fork

This fork preserves Status Trio's original license and attribution. It changes the popup presentation while retaining the monitoring, localization, configurable section order, keyboard shortcuts, and output switching.

## Design

- On macOS 26+, use a transparent AppKit panel with SwiftUI Liquid Glass surfaces. This lets glass sample the desktop instead of an opaque popover shell. A shared GlassEffectContainer batches rendering without merging separate cards. Older systems and Swift 6.1 builds retain NSPopover and system material backgrounds.
- Group battery, network, and audio in rounded glass surfaces with a subtle edge highlight, white circular badges, and a restrained dark tint for legible light content. The panel follows the control-center visual treatment without changing system appearance.
- Use native sliders and switches. Output devices use a compact selected row with a checkmark; long names truncate in the middle and retain a full tooltip and accessibility label.
- Keep critical numbers distinct from secondary status text. Follow the selected app locale for numeric formatting.
- Settings → panel → Preview panel opens the actual live popup. This closes the settings window first, so the preview uses the same activation and dismissal behavior as a menu-bar click.
- Respect Reduce Transparency with opaque system backgrounds. Do not add continuous animations, custom rendering loops, private material APIs, or extra monitoring timers.
- Keep the native menu-bar button and accessibility actions, using a compact slot and a circular selection even for wide icon configurations. Selection clears on dismissal and after the context menu closes.
- The transparent panel stays within the active display, resizes when detail views or output lists change, and closes on Escape, outside clicks or application deactivation. Temporary key-window changes and attached password sheets do not dismiss the panel. Reopening the app while its panel is visible preserves that panel; Settings remains available from its gear button.

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
