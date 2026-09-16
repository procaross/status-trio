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
        Image(systemName: symbol)
            .font(.system(size: 17, weight: .medium))
            .foregroundStyle(tint)
            .environment(\.colorScheme, .light)
            .frame(width: 40, height: 40)
            .background(Color.white.opacity(0.92), in: Circle())
            .accessibilityHidden(true)
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
