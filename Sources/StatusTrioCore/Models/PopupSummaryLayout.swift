struct PopupSummaryRow: Identifiable, Equatable {
    let sections: [PopupSection]
    var id: String { sections.map(\.rawValue).joined(separator: "-") }
}

enum PopupSummaryLayout {
    /// Pair adjacent compact summaries without changing the user's section order.
    /// Audio and Bluetooth retain full width for their interactive controls.
    static func rows(_ sections: [PopupSection]) -> [PopupSummaryRow] {
        var rows: [PopupSummaryRow] = []
        var index = 0
        while index < sections.count {
            if index + 1 < sections.count,
               Set([sections[index], sections[index + 1]]) == Set([.battery, .network]) {
                rows.append(PopupSummaryRow(sections: Array(sections[index...index + 1])))
                index += 2
            } else {
                rows.append(PopupSummaryRow(sections: [sections[index]]))
                index += 1
            }
        }
        return rows
    }
}
