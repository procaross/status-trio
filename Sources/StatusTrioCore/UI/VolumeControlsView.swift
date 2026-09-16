// Modified in the procaross/status-trio UI fork.
import SwiftUI

struct VolumeControlsView: View {
    @EnvironmentObject private var localization: Localization
    @ObservedObject var settings: SettingsStore
    let volume: VolumeStatus
    let isEnabled: Bool
    let onVolumeChange: (Double) -> Void
    let onToggleMute: () -> Void
    let onSelectOutputDevice: (AudioOutputDevice) -> Void
    let onOpenSoundSettings: () -> Void

    @State private var draftVolume = 0.0
    @State private var isAdjusting = false

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 12) {
                PopoverStatusBadge(symbol: "speaker.wave.2", tint: .indigo)
                VStack(alignment: .leading, spacing: 4) {
                    Text(localization.string(.settingsPopupOrderVolume))
                        .font(.system(size: 12, weight: .medium))
                    Text(StatusPresentation.volumeSubtitle(volume, localization: localization))
                        .font(.system(size: 11))
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                        .truncationMode(.middle)
                }
                Spacer(minLength: 4)
                Text(percentageText)
                    .font(.system(size: 16, weight: .medium, design: .rounded))
                    .monospacedDigit()
                PopoverIconButton(
                    symbol: "ellipsis",
                    title: localization.string(.volumeActionOpenSettings),
                    action: onOpenSoundSettings
                )
            }

            HStack(spacing: 10) {
                PopoverIconButton(
                    symbol: volume.isMuted ? "speaker.slash" : "speaker.wave.1",
                    title: localization.string(volume.isMuted ? .volumeUnmuted : .volumeMuted),
                    action: onToggleMute
                )
                .disabled(!isEnabled)
                .accessibilityValue(volume.isMuted ? localization.string(.volumeMuted) : "")

                Slider(
                    value: Binding(
                        get: { draftVolume },
                        set: { newValue in
                            draftVolume = newValue
                            updateVolume(newValue)
                        }
                    ),
                    in: 0...1,
                    onEditingChanged: handleVolumeEditing
                )
                .controlSize(.large)
                .tint(volume.isMuted ? Color.secondary : Color.accentColor)
                .disabled(!isEnabled)
                .accessibilityLabel(localization.string(.volumeAccessibilityLabel))
                .accessibilityValue(percentageText)

                Image(systemName: "speaker.wave.3")
                    .font(.system(size: 12))
                    .foregroundStyle(.secondary)
                    .accessibilityHidden(true)
            }
            .padding(.vertical, 2)

            Text(localization.string(.volumeOutputTitle))
                .font(.system(size: 10, weight: .medium))
                .foregroundStyle(.secondary)
                .padding(.top, 2)
                .padding(.leading, 4)

            OutputDeviceList(
                settings: settings,
                devices: volume.outputDevices,
                onSelect: onSelectOutputDevice
            )
        }
        .onAppear(perform: synchronizeVolume)
        .onChange(of: volume.scalar) { _, _ in
            guard !isAdjusting else { return }
            synchronizeVolume()
        }
    }

    private var percentageText: String {
        guard let scalar = volume.scalar, scalar.isFinite else { return "—" }
        let displayedScalar = isAdjusting ? draftVolume : scalar
        return min(1, max(0, displayedScalar)).formatted(
            .percent.precision(.fractionLength(0)).locale(localization.resolvedLanguage.locale)
        )
    }

    private func handleVolumeEditing(_ isEditing: Bool) {
        isAdjusting = isEditing
        if !isEditing { synchronizeVolume() }
    }

    private func updateVolume(_ newValue: Double) {
        let scalar = volume.scalar ?? -1
        guard scalar.isFinite,
              abs(newValue - min(1, max(0, scalar))) >= 0.0005 else {
            return
        }
        onVolumeChange(newValue)
    }

    private func synchronizeVolume() {
        guard let scalar = volume.scalar, scalar.isFinite else {
            draftVolume = 0
            return
        }
        draftVolume = min(1, max(0, scalar))
    }
}
