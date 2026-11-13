import NestKit

/// The colours of a card in one state.
struct NestCardPalette: Hashable, Sendable {
    let fill: NestColor
    let border: NestColor

    init(_ state: NestCardState, accent: NestAccent = .clay) {
        if state.isPressed {
            (fill, border) = (.surface3, .lineStrong)
        } else if state.isSelected {
            (fill, border) = (.surface2, accent.fill)
        } else if state.isHovered {
            (fill, border) = (.surface2, .lineStrong)
        } else {
            (fill, border) = (.surface1, .line)
        }
    }
}
