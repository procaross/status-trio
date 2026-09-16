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

    private func makeLocalization() -> Localization {
        let suiteName = "StatusTrioCoreTests.SettingsHitArea.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)!
        defaults.removePersistentDomain(forName: suiteName)
        let localization = Localization(defaults: defaults, preferredLanguages: ["en"])
        localization.setPreference(.language(.simplifiedChinese))
        return localization
    }

}
