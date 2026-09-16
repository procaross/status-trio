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
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 8) {
                Text(localization.string(.settingsPopupOrderVolume))
                    .font(.system(size: 13, weight: .semibold))
                Spacer(minLength: 4)
                Text(percentageText)
                    .font(.system(size: 11, weight: .medium))
                    .monospacedDigit()
                    .opacity(0.8)
            }
            .padding(.horizontal, 2)

            HStack(spacing: 10) {
                Button(action: onToggleMute) {
                    Image(systemName: volume.isMuted ? "speaker.slash.fill" : "speaker.wave.1.fill")
                        .font(.system(size: 12))
                        .frame(width: 24, height: 28)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .disabled(!isEnabled)
                .help(localization.string(volume.isMuted ? .volumeUnmuted : .volumeMuted))
                .accessibilityLabel(localization.string(volume.isMuted ? .volumeUnmuted : .volumeMuted))
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
                .controlSize(.mini)
                .tint(volume.isMuted ? Color.secondary : (colorScheme == .dark ? Color.white : Color.accentColor))
                .disabled(!isEnabled)
                .frame(minHeight: 28)
                .accessibilityLabel(localization.string(.volumeAccessibilityLabel))
                .accessibilityValue(percentageText)

                Button { showsOutputs.toggle() } label: {
                    PopoverStatusBadge(symbol: "airplay.audio", tint: .blue, size: 28)
                        .contentShape(Circle())
                }
                .buttonStyle(.plain)
                .help(StatusPresentation.volumeSubtitle(volume, localization: localization))
                .accessibilityLabel(localization.string(.volumeOutputTitle))
                .accessibilityValue(localization.string(showsOutputs ? .volumeOutputCollapse : .volumeOutputExpand))
            }

            if showsOutputs {
                Text(StatusPresentation.volumeSubtitle(volume, localization: localization))
                    .font(.system(size: 11, weight: .medium))
                    .opacity(0.85)
                    .lineLimit(1)
                    .truncationMode(.middle)
                    .padding(.top, 6)
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
