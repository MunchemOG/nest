/// One task for Swift: what to build and the test that proves it is built.
public struct QueueTask: Sendable, Equatable {
    /// The task's id, such as `S2-01`.
    public let id: String
    /// What the task builds.
    public let goal: String
    /// The test that must pass for the task to count as done.
    public let doneMeans: String
    /// What must be merged first, as written in the queue.
    public let needs: String

    /// A task with the given id, goal, test and needs.
    public init(id: String, goal: String, doneMeans: String, needs: String) {
        self.id = id
        self.goal = goal
        self.doneMeans = doneMeans
        self.needs = needs
    }

    /// The git branch the task is built on.
    public var branch: String { "task/\(id)" }
}
