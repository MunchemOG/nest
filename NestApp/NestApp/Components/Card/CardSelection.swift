/// The one selected card in a list, if any. Holding a single id means two can never be selected.
struct CardSelection<ID: Hashable>: Hashable {
    private(set) var selected: ID?

    init(selected: ID? = nil) {
        self.selected = selected
    }

    /// Selects `id`, unselecting whichever card was selected before.
    mutating func select(_ id: ID) {
        selected = id
    }

    /// Leaves nothing selected.
    mutating func clear() {
        selected = nil
    }

    /// Whether the card with `id` is the selected one.
    func isSelected(_ id: ID) -> Bool {
        selected == id
    }
}
