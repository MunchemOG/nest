/// One task in Swift's queue: what to build, the test that proves it, how much it matters and what it waits for.
public struct QueuedTask: Sendable, Equatable {
    /// The task's id, such as `S2-02`.
    public let id: String
    /// What the task builds.
    public let goal: String
    /// The test that must pass for the task to count as done.
    public let doneMeans: String
    /// Higher goes first; tasks with the same priority go in the order they were added.
    public let priority: Int
    /// The ids of tasks that must be done first.
    public let needs: [String]
    /// Who added the task.
    public let source: QueueSource
    /// Where the task is now.
    public let state: QueueState

    /// A task with the given fields, queued unless a state is given.
    public init(
        id: String,
        goal: String,
        doneMeans: String,
        priority: Int = 0,
        needs: [String] = [],
        source: QueueSource = .you,
        state: QueueState = .queued
    ) {
        self.id = id
        self.goal = goal
        self.doneMeans = doneMeans
        self.priority = priority
        self.needs = needs
        self.source = source
        self.state = state
    }
}
