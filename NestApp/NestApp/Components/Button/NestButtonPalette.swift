import NestKit

/// The colours of a button for its variant and state. Nil means none is drawn.
struct NestButtonPalette: Hashable, Sendable {
    let fill: NestColor?
    let border: NestColor?
    let label: NestColor

    init(_ variant: NestButtonVariant, _ state: NestButtonState) {
        let phase: Phase = !state.isEnabled ? .disabled : state.isPressed ? .pressed : state.isHovered ? .hover : .rest
        switch (variant, phase) {
        case (.primary, .rest): (fill, border, label) = (.clay, nil, .onClay)
        case (.primary, .hover): (fill, border, label) = (.claySoft, nil, .onClay)
        case (.primary, .pressed): (fill, border, label) = (.clayDeep, nil, .onClay)
        case (.primary, .disabled): (fill, border, label) = (.surface2, nil, .textMuted)
        case (.secondary, .rest): (fill, border, label) = (nil, .lineStrong, .textPrimary)
        case (.secondary, .hover): (fill, border, label) = (.surface2, .lineStrong, .textPrimary)
        case (.secondary, .pressed): (fill, border, label) = (.surface3, .lineStrong, .textPrimary)
        case (.secondary, .disabled): (fill, border, label) = (nil, .line, .textMuted)
        case (.quiet, .rest): (fill, border, label) = (nil, nil, .textSecondary)
        case (.quiet, .hover): (fill, border, label) = (.surface2, nil, .textPrimary)
        case (.quiet, .pressed): (fill, border, label) = (.surface3, nil, .textPrimary)
        case (.quiet, .disabled): (fill, border, label) = (nil, nil, .textMuted)
        }
    }

    private enum Phase { case rest, hover, pressed, disabled }
}
