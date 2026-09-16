// Modified in the procaross/status-trio UI fork.
import SwiftUI

struct BatteryStatusView: View {
    @EnvironmentObject private var localization: Localization
    let battery: BatteryStatus
    let onOpenBatterySettings: () -> Void

    var body: some View {
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
