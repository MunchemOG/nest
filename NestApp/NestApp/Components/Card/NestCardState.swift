/// What is happening to a card right now.
struct NestCardState: Hashable, Sendable {
    /// The pointer is over it.
    var isHovered = false
    /// It is being pressed.
    var isPressed = false
    /// It is the one chosen card in its list.
    var isSelected = false
    /// It has keyboard focus.
    var isFocused = false

    static let rest = NestCardState()
    static let hover = NestCardState(isHovered: true)
    static let pressed = NestCardState(isHovered: true, isPressed: true)
    static let selected = NestCardState(isSelected: true)
    static let focused = NestCardState(isFocused: true)
}
