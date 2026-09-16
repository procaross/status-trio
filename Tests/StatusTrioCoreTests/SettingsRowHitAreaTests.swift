// Modified in the procaross/status-trio UI fork.
import AppKit
import SwiftUI
import XCTest
@testable import StatusTrioCore

@MainActor
final class SettingsRowHitAreaTests: XCTestCase {
    func testPopupToolbarControlsKeepUsableSizeWithLongLocalizedLabels() {
        // Measure the public layout contract, not SwiftUI's private subview tree.
        // The toolbar must retain its hit area even with a long accessibility label.
        for title in ["设置…", "Einstellungen öffnen…", "فتح الإعدادات"] {
            let view = PopoverIconButton(symbol: "gearshape", title: title, action: {})
            let hostingView = NSHostingView(rootView: view)
            hostingView.layoutSubtreeIfNeeded()
            XCTAssertGreaterThanOrEqual(hostingView.fittingSize.width, 28)
            XCTAssertGreaterThanOrEqual(hostingView.fittingSize.height, 28)
            XCTAssertLessThanOrEqual(hostingView.fittingSize.width, 44)
        }
    }

    func testPreferenceCheckboxRowExpandsToAvailableWidth() {
        let localization = makeLocalization()
        let view = PreferenceCheckboxRow(
            label: .settingsBatteryShowPercentage,
            isOn: .constant(false)
        )
        .environmentObject(localization)
        let controller = NSHostingController(rootView: view)
        let size = controller.sizeThatFits(in: NSSize(width: 300, height: 40))
        XCTAssertEqual(size.width, 300, accuracy: 0.5)
        XCTAssertGreaterThan(size.height, 0)
    }

    func testBatteryTileFitsHalfWidthWithLocalizedText() {
        let localization = makeLocalization()
        for language in [AppLanguage.simplifiedChinese, .german, .arabic] {
            localization.setPreference(.language(language))
            let tile = BatteryStatusView(battery: .placeholder, onOpenBatterySettings: {}, isTile: true)
                .environmentObject(localization)
            let controller = NSHostingController(rootView: tile)
            let size = controller.sizeThatFits(in: NSSize(width: 154, height: 600))
            XCTAssertEqual(size.width, 154, accuracy: 0.5)
            XCTAssertLessThanOrEqual(size.height, 68)
        }
    }

    func testAudioStartsCompactEvenWithManyOutputDevices() {
        let suite = "StatusTrioCoreTests.AudioLayout.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suite)!
        defer { defaults.removePersistentDomain(forName: suite) }
        let devices = (1...12).map {
            AudioOutputDevice(id: UInt32($0), name: "Display \($0)", isCurrent: $0 == 1)
        }
        let view = VolumeControlsView(settings: SettingsStore(defaults: defaults),
            volume: VolumeStatus(scalar: 0.5, isMuted: false, deviceName: "Display 1", outputDevices: devices),
            isEnabled: true, onVolumeChange: { _ in }, onToggleMute: {},
            onSelectOutputDevice: { _ in }, onOpenSoundSettings: {})
            .environmentObject(makeLocalization())
        let controller = NSHostingController(rootView: view)
        let size = controller.sizeThatFits(in: NSSize(width: 292, height: 1000))
        XCTAssertLessThanOrEqual(size.height, 60)
        XCTAssertGreaterThan(size.height, 40)
    }

    private func makeLocalization() -> Localization {
        let suiteName = "StatusTrioCoreTests.SettingsHitArea.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)!
        defaults.removePersistentDomain(forName: suiteName)
        let localization = Localization(defaults: defaults, preferredLanguages: ["en"])
        localization.setPreference(.language(.simplifiedChinese))
        return localization
    }

}
