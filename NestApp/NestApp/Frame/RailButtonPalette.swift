import NestKit

/// The colours of a rail button.
struct RailButtonPalette: Hashable, Sendable {
    let fill: NestColor?
    let icon: NestColor
    let marker: NestColor?

    init(isSelected: Bool, isHovered: Bool, accent: NestAccent = .clay) {
        if isSelected {
            (fill, icon, marker) = (.surface3, .textPrimary, accent.fill)
        } else if isHovered {
            (fill, icon, marker) = (.surface2, .textPrimary, nil)
        } else {
            (fill, icon, marker) = (nil, .textMuted, nil)
        }
    }
}
