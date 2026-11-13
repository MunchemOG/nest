import NestKit

/// The colours of a rail button.
struct RailButtonPalette: Hashable, Sendable {
    let fill: NestColor?
    let icon: NestColor
    let marker: NestColor?

    init(isSelected: Bool, isHovered: Bool) {
        if isSelected {
            (fill, icon, marker) = (.surface3, .textPrimary, .clay)
        } else if isHovered {
            (fill, icon, marker) = (.surface2, .textPrimary, nil)
        } else {
            (fill, icon, marker) = (nil, .textMuted, nil)
        }
    }
}
