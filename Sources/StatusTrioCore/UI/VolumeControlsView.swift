// Modified in the procaross/status-trio UI fork.
import SwiftUI

struct VolumeControlsView: View {
    @Environment(\.colorScheme) private var colorScheme
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
    @State private var showsOutputs = false

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(localization.string(.settingsPopupOrderVolume))
                        .font(.system(size: 13, weight: .semibold))
                    Text(StatusPresentation.volumeSubtitle(volume, localization: localization))
                        .font(.system(size: 11))
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                        .truncationMode(.middle)
                }
                Spacer(minLength: 4)
                Text(percentageText)
                    .font(.system(size: 12, weight: .medium, design: .rounded))
                    .monospacedDigit()
                Button { showsOutputs.toggle() } label: {
                    PopoverStatusBadge(symbol: "airplay.audio", tint: .blue, size: 30)
                        .contentShape(Circle())
                }
                .buttonStyle(.plain)
                .help(localization.string(.volumeOutputTitle))
                .accessibilityLabel(localization.string(.volumeOutputTitle))
                .accessibilityValue(localization.string(showsOutputs ? .volumeOutputCollapse : .volumeOutputExpand))
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
                .controlSize(.small)
                .tint(volume.isMuted ? Color.secondary : (colorScheme == .dark ? Color.white : Color.accentColor))
                .disabled(!isEnabled)
                .frame(minHeight: 24)
                .accessibilityLabel(localization.string(.volumeAccessibilityLabel))
                .accessibilityValue(percentageText)

                Image(systemName: "speaker.wave.3")
                    .font(.system(size: 12))
                    .foregroundStyle(.secondary)
                    .accessibilityHidden(true)
            }
            .padding(.vertical, 2)

            if showsOutputs {
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
        }
        .contextMenu {
            Button(localization.string(.volumeActionOpenSettings), action: onOpenSoundSettings)
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
