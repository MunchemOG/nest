/// Which one-tap control an event's row offers.
public enum UndoChoice: Hashable, Sendable {
    /// Reverse this action.
    case undo
    /// Put back what this undo reversed.
    case redo
    /// Nothing to reverse.
    case none

    /// The choice for `event`, given whether it has already been reversed.
    public init(for event: NestEvent, isUndone: Bool) {
        guard event.undo != nil, !isUndone else {
            self = .none
            return
        }
        switch event.kind {
        case .action, .note: self = .undo
        case .undo: self = .redo
        default: self = .none
        }
    }
}
