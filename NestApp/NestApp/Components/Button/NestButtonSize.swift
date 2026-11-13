import NestKit

/// A button's size, built from the spacing and type tokens.
enum NestButtonSize: String, CaseIterable, Hashable, Sendable {
    /// Inline actions in rows and needs-you cards.
    case small
    /// The default.
    case regular
    /// The actions in a bird's close-up.
    case large

    /// The label's text style.
    var font: NestFont {
        switch self {
        case .small, .regular: .label
        case .large: .body
        }
    }

    /// Space above and below the label.
    var verticalPadding: Double {
        switch self {
        case .small: NestSpace.s1
        case .regular, .large: NestSpace.s2
        }
    }

    /// Space either side of the label.
    var horizontalPadding: Double {
        switch self {
        case .small: NestSpace.s3
        case .regular: NestSpace.s4
        case .large: NestSpace.s5
        }
    }

    /// The button's height.
    var height: Double { font.lineHeight + 2 * verticalPadding }
}
