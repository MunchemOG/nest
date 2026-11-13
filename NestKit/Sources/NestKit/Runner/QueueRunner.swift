/// Runs Swift's queue back to back: claims the next ready task, builds it on a fresh branch, and marks it done or held.
public struct QueueRunner: Sendable {
    /// Where the tasks come from and where their ends are written.
    public let queue: TaskQueue
    /// What builds each task.
    public let runner: ManualRunner

    /// A runner that builds `queue`'s tasks with `runner`.
    public init(queue: TaskQueue, runner: ManualRunner) {
        self.queue = queue
        self.runner = runner
    }

    /// Builds tasks one after another until none is ready, and returns how each ended, in order.
    public func runUntilEmpty() async throws -> [RunOutcome] {
        var outcomes: [RunOutcome] = []
        while let next = try await queue.claim() {
            let outcome = try await runner.run(QueueTask(next))
            try await queue.finish(next.id, as: outcome.isDone ? .done : .held)
            outcomes.append(outcome)
        }
        return outcomes
    }
}
