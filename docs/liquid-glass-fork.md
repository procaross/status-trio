# Liquid Glass panel fork

This fork preserves Status Trio's original license and attribution. It changes the popup presentation while retaining the monitoring, localization, configurable section order, keyboard shortcuts, and output switching.

## Design

- Use the system NSPopover surface, with no extra opaque hosting background or nested blur. A build linked against macOS 26 or newer adopts the system Liquid Glass presentation. Older systems retain their native popover material.
- Group battery, network, and audio with spacing, restrained tinted symbols and lightweight section fills instead of separator rules.
- Use native sliders and switches. Output devices use a compact selected row with a checkmark; long names truncate in the middle and retain a full tooltip and accessibility label.
- Keep critical numbers distinct from secondary status text. Follow the selected app locale for numeric formatting.
- Settings → panel → Preview panel opens the actual live popup. This closes the settings window first, so the preview uses the same activation and dismissal behavior as a menu-bar click.
- Respect Reduce Transparency. Do not add continuous animations, custom rendering loops, private material APIs, or extra monitoring timers.

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
