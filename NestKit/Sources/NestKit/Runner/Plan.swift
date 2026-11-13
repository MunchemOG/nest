/// What plan mode made of a rough idea: small tasks in build order, or why the idea was dropped.
public struct Plan: Sendable, Equatable {
    /// The tasks, in the order they should be built; empty when the idea was dropped.
    public let tasks: [QueuedTask]
    /// Why the idea was dropped, such as needing something outside the Nest's code; nil when it was planned.
    public let dropped: String?

    /// A plan with the given tasks, or a dropped idea with its reason.
    public init(tasks: [QueuedTask], dropped: String? = nil) {
        self.tasks = tasks
        self.dropped = dropped
    }
}
