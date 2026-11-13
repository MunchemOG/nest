/// What is happening to a button right now.
struct NestButtonState: Hashable, Sendable {
    /// False when the button cannot be pressed.
    var isEnabled = true
    /// The pointer is over it.
    var isHovered = false
    /// It is being pressed.
    var isPressed = false
    /// It has keyboard focus.
    var isFocused = false

    /// Whether to draw the focus ring.
    var showsFocusRing: Bool { isEnabled && isFocused }

    static let rest = NestButtonState()
    static let hover = NestButtonState(isHovered: true)
    static let pressed = NestButtonState(isHovered: true, isPressed: true)
    static let focused = NestButtonState(isFocused: true)
    static let disabled = NestButtonState(isEnabled: false)
}
