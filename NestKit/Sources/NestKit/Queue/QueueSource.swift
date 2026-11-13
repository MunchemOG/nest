/// Who put a task in the queue.
public enum QueueSource: String, Sendable, Equatable, CaseIterable {
    /// You, by chat or from `docs/queue.md`.
    case you
    /// Crow, from a pitch you approved.
    case crow
}
