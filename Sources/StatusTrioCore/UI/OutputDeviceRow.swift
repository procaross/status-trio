// Modified in the procaross/status-trio UI fork.
import SwiftUI

struct OutputDeviceRow: View {
    @EnvironmentObject private var localization: Localization
    let device: AudioOutputDevice
    let onSelect: (AudioOutputDevice) -> Void

    @Environment(\.colorScheme) private var colorScheme
    @State private var isHovered = false

    var body: some View {
        Button {
            onSelect(device)
        } label: {
            HStack(spacing: 10) {
                Image(systemName: deviceSymbolName)
                    .font(.system(size: 15, weight: .regular))
                    .foregroundStyle(device.isCurrent ? selectionColor : Color.secondary)
                    .frame(width: 24, height: 24)
                    .accessibilityHidden(true)

                Text(displayName)
                    .font(.system(size: 12, weight: device.isCurrent ? .medium : .regular))
                    .lineLimit(1)
                    .truncationMode(.middle)
                    .frame(maxWidth: .infinity, alignment: .leading)

                if device.isCurrent {
                    Image(systemName: "checkmark")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(selectionColor)
                        .accessibilityHidden(true)
                }
            }
            .padding(.horizontal, 9)
            .padding(.vertical, 6)
            .background {
                RoundedRectangle(cornerRadius: 11, style: .continuous)
                    .fill(device.isCurrent ? selectionColor.opacity(0.12) : Color.primary.opacity(isHovered ? 0.055 : 0))
            }
            .contentShape(RoundedRectangle(cornerRadius: 11))
        }
        .buttonStyle(.plain)
        .onHover { isHovered = $0 }
        .help(displayName)
        .accessibilityLabel(displayName)
        .accessibilityValue(device.isCurrent ? localization.string(.volumeOutputCurrent) : "")
    }

    private var selectionColor: Color { colorScheme == .dark ? .white : .accentColor }

    private var displayName: String {
        device.name ?? localization.string(.volumeOutputUnknownDevice)
    }

    private var deviceSymbolName: String {
        let name = (device.name ?? "").lowercased()
        if name.contains("airpods pro") {
            return "airpodspro"
        } else if name.contains("airpods max") {
            return "airpodsmax"
        } else if name.contains("airpods") {
            return "airpods"
        } else if name.contains("headphone") || name.contains("耳机") {
            return "headphones"
        } else if name.contains("display") || name.contains("monitor") || name.contains("显示器") || name.contains("hdmi") {
            return "display"
        } else if name.contains("tv") || name.contains("television") {
            return "tv"
        } else if name.contains("macbook") || name.contains("internal") || name.contains("内置") {
            return "laptopcomputer"
        }
        return device.isCurrent ? "hifispeaker.fill" : "hifispeaker"
    }
}
