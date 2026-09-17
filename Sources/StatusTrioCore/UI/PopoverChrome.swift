import SwiftUI

// Modified in the procaross/status-trio UI fork.
/// Let AppKit render the glass edge instead of painting additional bevels.
struct PopoverSectionSurface: ViewModifier {
    @Environment(\.accessibilityReduceTransparency) private var reduceTransparency

    func body(content: Content) -> some View {
        content
            .padding(12)
            .frame(maxWidth: .infinity, alignment: .leading)
            .modifier(PopoverGlassSurface(reduceTransparency: reduceTransparency))
    }
}

struct PopoverGlassSurface: AnimatableModifier {
    let reduceTransparency: Bool
    var radius: CGFloat = 32
    nonisolated var highlight: Double = 0
    var surfaceScale: CGFloat = 1
    nonisolated var animatableData: Double {
        get { highlight }
        set { highlight = newValue }
    }
    private var shape: RoundedRectangle { RoundedRectangle(cornerRadius: radius, style: .continuous) }

    @ViewBuilder
    func body(content: Content) -> some View {
        if reduceTransparency {
            content.background(Color(nsColor: .controlBackgroundColor), in: shape.scale(surfaceScale))
        } else {
#if compiler(>=6.2)
            if #available(macOS 26.0, *) {
                content
                    .foregroundStyle(.white)
                    .environment(\.colorScheme, .dark)
                    .background {
                        NativePopoverGlass(radius: radius, highlight: highlight)
                            .overlay { shape.fill(.white.opacity(highlight * 0.10)) }
                            .scaleEffect(surfaceScale)
                            .allowsHitTesting(false)
                            .accessibilityHidden(true)
                    }
            } else {
                content.background(.ultraThinMaterial, in: shape.scale(surfaceScale))
            }
#else
            content.background(.ultraThinMaterial, in: shape.scale(surfaceScale))
#endif
        }
    }
}

/// A control group is not a Button: observe presses without capturing its slider
/// or child buttons. Only the glass scales, so dragging never shifts the track.
struct PopoverInteractiveSectionSurface: ViewModifier {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.accessibilityReduceTransparency) private var reduceTransparency
    @State private var isHovered = false
    @State private var isPressed = false

    func body(content: Content) -> some View {
        content
            .padding(12)
            .frame(maxWidth: .infinity, alignment: .leading)
            .modifier(PopoverGlassSurface(
                reduceTransparency: reduceTransparency,
                highlight: isPressed ? 1 : (isHovered ? 0.55 : 0),
                surfaceScale: reduceMotion ? 1 : (isPressed ? 0.975 : (isHovered ? 1.008 : 1))
            ))
            .overlay {
                PopoverPressObserver(isPressed: $isPressed)
                    .allowsHitTesting(false)
                    .accessibilityHidden(true)
            }
            .contentShape(RoundedRectangle(cornerRadius: 32, style: .continuous))
            .onHover { isHovered = $0 }
            .animation(reduceMotion ? nil : .spring(response: 0.26, dampingFraction: 0.72), value: isPressed)
            .animation(reduceMotion ? nil : .easeOut(duration: 0.16), value: isHovered)
    }
}

#if compiler(>=6.2)
@available(macOS 26.0, *)
private struct NativePopoverGlass: NSViewRepresentable {
    let radius: CGFloat
    let highlight: Double

    func makeNSView(context: Context) -> NSGlassEffectView {
        let view = NSGlassEffectView()
        view.style = .clear
        // Keep the optical surface light; white foreground content is configured
        // separately. Native glass supplies its own rim, highlights and shadow.
        view.appearance = NSAppearance(named: .aqua)
        view.tintColor = NSColor.black.withAlphaComponent(0.30)
        view.cornerRadius = radius
        return view
    }

    func updateNSView(_ view: NSGlassEffectView, context: Context) {
        view.cornerRadius = radius
        view.tintColor = NSColor.black.withAlphaComponent(0.30 - highlight * 0.07)
    }
}
#endif


struct PopoverStatusBadge: View {
    let symbol: String
    let tint: Color
    var size: CGFloat = 36

    var body: some View {
        PopoverBadgeImage(symbol: symbol, tint: NSColor(tint))
            .frame(width: size, height: size)
            .accessibilityHidden(true)
    }
}

/// Original-color symbols must not inherit glass foreground vibrancy: adding
/// vibrant green to a white badge washes the battery symbol out completely.
private struct PopoverBadgeImage: NSViewRepresentable {
    let symbol: String
    let tint: NSColor

    func makeNSView(context: Context) -> NonVibrantBadge { NonVibrantBadge() }
    func updateNSView(_ view: NonVibrantBadge, context: Context) {
        view.symbol = symbol
        view.tint = tint
        view.needsDisplay = true
    }
}

private final class NonVibrantBadge: NSView {
    var symbol = ""
    var tint = NSColor.systemBlue
    override var allowsVibrancy: Bool { false }

    override func draw(_ dirtyRect: NSRect) {
        NSColor.white.withAlphaComponent(0.94).setFill()
        NSBezierPath(ovalIn: bounds).fill()
        let configuration = NSImage.SymbolConfiguration(pointSize: 17, weight: .medium)
            .applying(NSImage.SymbolConfiguration(paletteColors: [tint]))
        guard let image = NSImage(systemSymbolName: symbol, accessibilityDescription: nil)?
            .withSymbolConfiguration(configuration) else { return }
        image.isTemplate = false
        let size = image.size
        image.draw(in: NSRect(x: bounds.midX - size.width / 2, y: bounds.midY - size.height / 2,
                              width: size.width, height: size.height))
    }
}

struct PopoverIconButton: View {
    let symbol: String
    let title: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: symbol)
                .font(.system(size: 12, weight: .medium))
                .frame(width: 28, height: 28)
                .contentShape(Circle())
        }
        .buttonStyle(PopoverQuietButtonStyle())
        .help(title)
        .accessibilityLabel(title)
    }
}

struct PopoverQuietButtonStyle: ButtonStyle {
    @Environment(\.isEnabled) private var isEnabled

    func makeBody(configuration: Configuration) -> some View {
        PopoverFeedbackBody(isPressed: configuration.isPressed, hasSurface: false) {
            configuration.label
                .foregroundStyle(isEnabled ? Color.secondary : Color.secondary.opacity(0.45))
                .background(Color.primary.opacity(configuration.isPressed ? 0.10 : 0.035), in: Circle())
        }
    }
}

/// Press feedback lasts for the entire hold; releasing invokes the native Button
/// once. No repeating timers or extra long-press action compete with the click.
struct PopoverControlButtonStyle: ButtonStyle {
    var hasSurface = false
    func makeBody(configuration: Configuration) -> some View {
        PopoverFeedbackBody(isPressed: configuration.isPressed, hasSurface: hasSurface) {
            configuration.label
        }
    }
}

private struct PopoverFeedbackBody<Content: View>: View {
    let isPressed: Bool
    let hasSurface: Bool
    @ViewBuilder let content: () -> Content
    @Environment(\.isEnabled) private var isEnabled
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.accessibilityReduceTransparency) private var reduceTransparency
    @State private var isHovered = false

    private var highlight: Double { !isEnabled ? 0 : (isPressed ? 1 : (isHovered ? 0.55 : 0)) }
    var body: some View {
        Group {
            if hasSurface {
                content().padding(12).frame(maxWidth: .infinity, alignment: .leading)
                    .modifier(PopoverGlassSurface(reduceTransparency: reduceTransparency, highlight: highlight))
            } else {
                content().brightness(highlight * 0.08)
            }
        }
        .scaleEffect(!isEnabled || reduceMotion ? 1 : (isPressed ? 0.96 : (isHovered ? 1.015 : 1)))
        .animation(reduceMotion ? nil : .spring(response: 0.24, dampingFraction: 0.8), value: isPressed)
        .animation(reduceMotion ? nil : .easeOut(duration: 0.16), value: isHovered)
        .onHover { isHovered = $0 }
    }
}
