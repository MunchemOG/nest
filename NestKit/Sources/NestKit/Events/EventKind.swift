/// The seven kinds of event in `docs/event-bus.md`.
public enum EventKind: String, CaseIterable, Hashable, Sendable, Decodable {
    /// Something a bird noticed; nothing changed.
    case signal
    /// Something a bird changed; always carries an undo.
    case action
    /// An action was reversed; its undo is the Redo.
    case undo
    /// Crow proposes a tool.
    case pitch
    /// Swift reports a run, or Peacock announces a post kit.
    case report
    /// Magpie wrote or linked memory.
    case note
    /// You or the app tell a bird something.
    case ask
}
