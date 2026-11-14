import Foundation

/// Runs Swift's queue back to back: claims the next ready task, builds it on a fresh branch, and marks it done or held.
/// It stands down between tasks when you arrive. With a merger, each green task is merged and the whole suite runs on main; if main goes red, the merge is rolled back.
public struct QueueRunner: Sendable {
    /// Where the tasks come from and where their ends are written.
    public let queue: TaskQueue
    /// What builds each task.
    public let runner: ManualRunner
    /// What merges green tasks, or nil to leave every task on its branch.
    public let merger: AutoMerge?
    /// The suite run on main after each merge.
    public let mainTests: [String]
    /// Where Swift's events go.
    public let publish: @Sendable (NestEvent) async -> Void
    /// Where each session's cost is logged, or nil to log nothing.
    public let usageLog: UsageLog?
    /// The budget checked before each task, or nil to run without one.
    public let budget: Budget?
    /// Whether you are at the Mac; Swift finishes its step and stands down when you arrive.
    public let presence: PresenceWatch?

    /// What a rollback tells you.
    public static let rollbackReason = "The whole suite failed on main after the merge."

    /// A runner that builds `queue`'s tasks with `runner`, merging green ones with `merger` and checking main with `mainTests`.
    public init(
        queue: TaskQueue,
        runner: ManualRunner,
        merger: AutoMerge? = nil,
        mainTests: [String] = [],
        publish: @escaping @Sendable (NestEvent) async -> Void = { _ in },
        usageLog: UsageLog? = nil,
        budget: Budget? = nil,
        presence: PresenceWatch? = nil
    ) {
        self.queue = queue
        self.runner = runner
        self.merger = merger
        self.mainTests = mainTests
        self.publish = publish
        self.usageLog = usageLog
        self.budget = budget
        self.presence = presence
    }

    /// Builds tasks one after another until none is ready, and returns how each ended, in order.
    public func runUntilEmpty() async throws -> [RunOutcome] {
        try await run().outcomes
    }

    /// Builds tasks one after another until none is ready or the budget says to pause.
    public func run() async throws -> QueueRun {
        var outcomes: [RunOutcome] = []
        while true {
            if let presence, await presence.standsSwiftDown {
                return QueueRun(outcomes: outcomes, paused: await presence.reason)
            }
            if let budget, case .pause(let why) = try await budget.decide() {
                return QueueRun(outcomes: outcomes, paused: why)
            }
            guard let next = try await queue.claim() else { break }
            let started = Date.now
            let outcome = try await runner.run(QueueTask(next))
            if let usageLog, let usage = outcome.usage {
                try await usageLog.record(task: next.id, usage: usage, started: started, ended: .now)
            }
            let kept = outcome.isDone ? try await mergeAndCheck(outcome) : false
            try await queue.finish(next.id, as: kept ? .done : .held)
            outcomes.append(outcome)
        }
        return QueueRun(outcomes: outcomes, paused: nil)
    }

    /// Merges a green task and runs the whole suite on main, rolling the merge back if it fails. Returns whether it stayed.
    private func mergeAndCheck(_ outcome: RunOutcome) async throws -> Bool {
        guard let merger else { return true }
        let merged = try await merger.merge(outcome)
        await publish(merged)
        guard !mainTests.isEmpty else { return true }
        let suite = try await Shell().run(mainTests, in: merger.repository, watch: runner.watch)
        guard !suite.succeeded else { return true }
        let rollback = try await merger.undo(merged, why: Self.rollbackReason, attention: .inbox)
        await publish(rollback)
        return false
    }
}
