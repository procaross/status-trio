// Modified in the procaross/status-trio UI fork.
import AppKit
import SwiftUI

struct WiFiStatusView: View {
    @EnvironmentObject private var localization: Localization
    let wifi: WiFiStatus
    let onOpenDetails: (Bool) -> Void
    let onRequestNameAccess: () -> Void
    let onOpenWiFiSettings: () -> Void
    let onOpenLocationSettings: () -> Void
    var isTile = false

    @ViewBuilder var body: some View {
        if isTile {
            Button { onOpenDetails(NSEvent.modifierFlags.contains(.option)) } label: {
                HStack(spacing: 10) {
                    PopoverStatusBadge(symbol: networkSymbol, tint: .blue)
                    VStack(alignment: .leading, spacing: 3) {
                        Text(localization.string(.wifiTitle))
                            .font(.system(size: 13, weight: .semibold))
                            .lineLimit(1)
                        Text(StatusPresentation.wifiSubtitle(wifi, localization: localization))
                            .font(.system(size: 12, weight: .medium))
                            .opacity(0.9)
                            .lineLimit(1)
                            .truncationMode(.middle)
                    }
                    Spacer(minLength: 0)
                }
                .frame(maxWidth: .infinity, minHeight: 40, maxHeight: 40, alignment: .leading)
                .contentShape(Rectangle())
            }
            .buttonStyle(PopoverControlButtonStyle(hasSurface: true))
            .accessibilityLabel(wifiAccessibilityLabel)
            .help(subtitle)
            .contextMenu {
                Button(localization.string(.wifiActionOpenSettings), action: onOpenWiFiSettings)
            }
        } else {
            row
        }
    }

    private var row: some View {
        HStack(spacing: 10) {
            Button {
                switch StatusMappings.wifiSummaryAction(for: wifi) {
                case .openDetails:
                    onOpenDetails(NSEvent.modifierFlags.contains(.option))
                case .requestNameAccess:
                    onRequestNameAccess()
                case .openLocationSettings:
                    onOpenLocationSettings()
                }
            } label: {
                HStack(spacing: 12) {
                    PopoverStatusBadge(symbol: networkSymbol, tint: wifi.state.isNetworkAssociated ? .teal : .secondary)
                    VStack(alignment: .leading, spacing: 4) {
                        Text(localization.string(.networkTitle))
                            .font(.system(size: 12, weight: .medium))
                        Text(subtitle)
                            .font(.system(size: 11))
                            .foregroundStyle(.secondary)
                            .lineLimit(2)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    Spacer(minLength: 4)
                    Image(systemName: "chevron.right")
                        .font(.system(size: 9, weight: .semibold))
                        .foregroundStyle(.tertiary)
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel(wifiAccessibilityLabel)

            PopoverIconButton(
                symbol: "ellipsis",
                title: localization.string(.wifiActionOpenSettings),
                action: onOpenWiFiSettings
            )
        }
    }

    private var networkSymbol: String {
        switch wifi.state {
        case .off, .unavailable: "wifi.slash"
        case .noInternet: "wifi.exclamationmark"
        case .hotspot: "personalhotspot"
        default: "wifi"
        }
    }

    private var subtitle: String {
        if let ssid = wifi.ssid, !ssid.isEmpty { return ssid }
        if wifi.state.isNetworkAssociated && wifi.nameAccess == .notDetermined {
            return localization.string(.wifiActionRequestNameAccess)
        }
        if wifi.state.isNetworkAssociated && (wifi.nameAccess == .denied || wifi.nameAccess == .restricted) {
            return localization.string(.wifiActionOpenLocationSettings)
        }
        return StatusPresentation.wifiSubtitle(wifi, localization: localization)
    }

    private var wifiAccessibilityLabel: String {
        if let ssid = wifi.ssid, !ssid.isEmpty {
            return localization.format(.wifiAccessibilityWithSSID, ssid, StatusPresentation.wifiValue(wifi, localization: localization))
        }
        return localization.format(.commonLabelValue, localization.string(.networkTitle), StatusPresentation.wifiValue(wifi, localization: localization))
    }
}
