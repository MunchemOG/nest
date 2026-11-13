import NestKit
import SwiftUI

/// The colour family that marks what you can press and keyboard focus. Wren's look sets it; clay unless told otherwise.
enum NestAccent: String, CaseIterable, Hashable, Sendable {
    case clay
    case sage
    case lagoon

    /// The accent named in a `wren.look.changed` event, or clay.
    init(name: String?) {
        self = NestAccent(rawValue: name ?? "") ?? .clay
    }

    /// Primary fills, links, focus.
    var fill: NestColor {
        switch self {
        case .clay: .clay
        case .sage: .sage
        case .lagoon: .lagoon
        }
    }

    /// Pressed fills.
    var deep: NestColor {
        switch self {
        case .clay: .clayDeep
        case .sage: .sageDeep
        case .lagoon: .lagoonDeep
        }
    }

    /// Highlights and text on the tint.
    var soft: NestColor {
        switch self {
        case .clay: .claySoft
        case .sage: .sageSoft
        case .lagoon: .lagoonSoft
        }
    }

    /// The translucent wash behind soft text.
    var tint: NestColor {
        switch self {
        case .clay: .clayTint
        case .sage: .sageTint
        case .lagoon: .lagoonTint
        }
    }

    /// Text and icons on the fill.
    var onFill: NestColor { .onClay }
}

extension EnvironmentValues {
    /// The current accent; primary controls and focus rings follow it.
    @Entry var nestAccent: NestAccent = .clay
}
