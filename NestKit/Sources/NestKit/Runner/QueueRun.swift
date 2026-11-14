/// How a run of the queue went: each task's ending, and why it stopped early, if it did.
public struct QueueRun: Sendable, Equatable {
    /// How each task that ran ended, in order.
    public let outcomes: [RunOutcome]
    /// Why Swift paused before the queue was empty, or nil if it ran out of ready tasks.
    public let paused: String?
}
