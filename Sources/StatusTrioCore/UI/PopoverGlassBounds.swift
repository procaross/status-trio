import SwiftUI

/// Geometry comes from the rendered cards, including expanded detail panels;
/// no fixed screen coordinates or assumptions about localized text heights.
struct PopoverGlassBounds: PreferenceKey {
    static var defaultValue: [Anchor<CGRect>] { [] }
    static func reduce(value: inout [Anchor<CGRect>], nextValue: () -> [Anchor<CGRect>]) {
        value.append(contentsOf: nextValue())
    }
}
