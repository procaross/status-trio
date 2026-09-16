// Modified in the procaross/status-trio UI fork.
import SwiftUI

struct BatteryStatusView: View {
    @EnvironmentObject private var localization: Localization
    let battery: BatteryStatus
    let onOpenBatterySettings: () -> Void
    var isTile = false

    @ViewBuilder var body: some View {
        if isTile {
            Button(action: onOpenBatterySettings) {
                VStack(alignment: .leading, spacing: 8) {
                    HStack(spacing: 8) {
                        PopoverStatusBadge(symbol: batterySymbolName, tint: batterySymbolColor, size: 32)
                        Text(localization.string(.settingsPopupOrderBattery))
                            .font(.system(size: 13, weight: .semibold))
                        Spacer(minLength: 0)
                    }
                    Spacer(minLength: 0)
                    Text(battery.isPresent ? battery.percentage.formatted(.percent.scale(1).locale(localization.resolvedLanguage.locale)) : "—")
                        .font(.system(size: 28, weight: .medium, design: .rounded))
                        .monospacedDigit()
                    Text(StatusPresentation.batterySubtitle(battery, localization: localization))
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                }
                .frame(maxWidth: .infinity, minHeight: 104, maxHeight: 104, alignment: .leading)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .help(localization.string(.batteryActionOpenSettings))
            .accessibilityLabel(battery.isPresent ? StatusPresentation.batteryTitle(battery, localization: localization) : localization.string(.batteryStateNotPresent))
        } else {
            row
        }
    }

    private var row: some View {
        HStack(spacing: 12) {
            PopoverStatusBadge(symbol: batterySymbolName, tint: batterySymbolColor)

            VStack(alignment: .leading, spacing: 4) {
                Text(localization.string(.settingsPopupOrderBattery))
                    .font(.system(size: 12, weight: .medium))
                Text(StatusPresentation.batterySubtitle(battery, localization: localization))
                    .font(.system(size: 11))
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer(minLength: 6)
            if battery.isPresent {
                Text(battery.percentage.formatted(.percent.scale(1).locale(localization.resolvedLanguage.locale)))
                    .font(.system(size: 27, weight: .medium, design: .rounded))
                    .monospacedDigit()
                    .accessibilityLabel(StatusPresentation.batteryTitle(battery, localization: localization))
                PopoverIconButton(
                    symbol: "ellipsis",
                    title: localization.string(.batteryActionOpenSettings),
                    action: onOpenBatterySettings
                )
            }
        }
        .padding(.vertical, 2)
    }

    private var batterySymbolName: String {
        guard battery.isPresent else { return "battery.slash" }
        if battery.isCharging || battery.isConnectedToPower {
            return "battery.100.bolt"
        }
        switch battery.percentage {
        case 88...100: return "battery.100"
        case 63..<88:  return "battery.75"
        case 38..<63:  return "battery.50"
        case 13..<38:  return "battery.25"
        default:       return "battery.0"
        }
    }

    private var batterySymbolColor: Color {
        guard battery.isPresent else { return .secondary }
        if battery.isCharging || battery.isConnectedToPower {
            return .green
        }
        if battery.isLowPowerMode {
            return .yellow
        }
        if battery.percentage <= 20 {
            return .red
        }
        return .primary
    }
}
