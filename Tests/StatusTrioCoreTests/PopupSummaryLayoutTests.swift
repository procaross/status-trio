import XCTest
@testable import StatusTrioCore

final class PopupSummaryLayoutTests: XCTestCase {
    func testAdjacentSummariesShareARowInEitherOrder() {
        XCTAssertEqual(PopupSummaryLayout.rows([.battery, .network, .volume]).map(\.sections),
                       [[.battery, .network], [.volume]])
        XCTAssertEqual(PopupSummaryLayout.rows([.network, .battery, .volume]).map(\.sections),
                       [[.network, .battery], [.volume]])
    }

    func testAudioAndBluetoothStayFullWidthWithoutReordering() {
        for selection: [PopupSection] in [[.battery, .volume, .network],
                                          [.bluetooth, .network, .battery, .volume],
                                          [.network, .bluetooth, .battery]] {
            let rows = PopupSummaryLayout.rows(selection)
            XCTAssertEqual(rows.flatMap(\.sections), selection)
            XCTAssertTrue(rows.filter { $0.sections.contains(.volume) || $0.sections.contains(.bluetooth) }
                .allSatisfy { $0.sections.count == 1 })
        }
    }

    func testHiddenSectionsDoNotLeaveEmptyTiles() {
        XCTAssertTrue(PopupSummaryLayout.rows([]).isEmpty)
        for section in PopupSection.allCases {
            XCTAssertEqual(PopupSummaryLayout.rows([section]).map(\.sections), [[section]])
        }
    }
}
