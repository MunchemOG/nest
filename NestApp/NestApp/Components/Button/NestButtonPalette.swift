import NestKit

/// The colours of a button for its variant and state. Nil means none is drawn.
struct NestButtonPalette: Hashable, Sendable {
    let fill: NestColor?
    let border: NestColor?
    let label: NestColor

    init(_ variant: NestButtonVariant, _ state: NestButtonState, accent: NestAccent = .clay) {
        let phase: Phase = !state.isEnabled ? .disabled : state.isPressed ? .pressed : state.isHovered ? .hover : .rest
        switch (variant, phase) {
        case (.primary, .rest): (fill, border, label) = (accent.fill, nil, accent.onFill)
        case (.primary, .hover): (fill, border, label) = (accent.soft, nil, accent.onFill)
        case (.primary, .pressed): (fill, border, label) = (accent.deep, nil, accent.onFill)
        case (.primary, .disabled): (fill, border, label) = (.surface2, nil, .textMuted)
        case (.solid, .rest): (fill, border, label) = (.textPrimary, nil, .surface0)
        case (.solid, .hover): (fill, border, label) = (.textPrimary, nil, accent.deep)
        case (.solid, .pressed): (fill, border, label) = (.textSecondary, nil, .surface0)
        case (.solid, .disabled): (fill, border, label) = (.surface2, nil, .textMuted)
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
