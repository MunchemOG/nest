/// How strongly a button asks to be pressed.
enum NestButtonVariant: String, CaseIterable, Hashable, Sendable {
    /// The one main action in a card: a clay fill.
    case primary
    /// The one main action on glass over the scene: a white fill, as in the approved Home.
    case solid
    /// Other actions: an outline.
    case secondary
    /// Small inline actions such as Undo in a row: text until hovered.
    case quiet
}
