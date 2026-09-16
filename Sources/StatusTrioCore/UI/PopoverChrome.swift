import SwiftUI

// Modified in the procaross/status-trio UI fork.
/// System glass provides the refraction and edge lighting; no painted imitation.
struct PopoverSectionSurface: ViewModifier {
    @Environment(\.accessibilityReduceTransparency) private var reduceTransparency

    func body(content: Content) -> some View {
        content
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .modifier(PopoverGlassSurface(reduceTransparency: reduceTransparency))
    }
}

struct PopoverGlassSurface: ViewModifier {
    let reduceTransparency: Bool
    var radius: CGFloat = 28
    private var shape: RoundedRectangle { RoundedRectangle(cornerRadius: radius, style: .continuous) }

    @ViewBuilder
    func body(content: Content) -> some View {
        if reduceTransparency {
            content.background(Color(nsColor: .controlBackgroundColor), in: shape)
        } else {
#if compiler(>=6.2)
            if #available(macOS 26.0, *) {
                content.glassEffect(.clear.tint(.black.opacity(0.22)), in: shape)
                    .overlay {
                        shape.strokeBorder(
                            LinearGradient(colors: [.white.opacity(0.85), .white.opacity(0.12), .white.opacity(0.55)],
                                           startPoint: .topLeading, endPoint: .bottomTrailing), lineWidth: 0.75
                        )
                        .allowsHitTesting(false)
                        .accessibilityHidden(true)
                    }
            } else {
                content.background(.ultraThinMaterial, in: shape)
            }
#else
            content.background(.ultraThinMaterial, in: shape)
#endif
        }
    }
}

struct PopoverGlassGroup<Content: View>: View {
    @ViewBuilder let content: () -> Content

    @ViewBuilder var body: some View {
#if compiler(>=6.2)
        if #available(macOS 26.0, *) {
            // Below the section gap, so adjacent surfaces never merge together.
            GlassEffectContainer(spacing: 6, content: content)
        } else {
            content()
        }
#else
        content()
#endif
    }
}

struct PopoverStatusBadge: View {
    let symbol: String
    let tint: Color

    var body: some View {
        PopoverBadgeImage(symbol: symbol, tint: NSColor(tint))
            .frame(width: 40, height: 40)
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
        configuration.label
            .foregroundStyle(isEnabled ? Color.secondary : Color.secondary.opacity(0.45))
            .background(Color.primary.opacity(configuration.isPressed ? 0.10 : 0.035), in: Circle())
    }
}
