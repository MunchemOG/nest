import Foundation

/// Swift running itself: once you are away, it brings in `docs/queue.md` from main, builds what is ready,
/// merges green work through its runner, and publishes `swift.report.ready` for any night that built something.
public struct SwiftShift: Sendable {
    /// What builds, merges and checks the tasks; its presence watch decides when Swift may start.
    public let runner: QueueRunner
    /// The branch the queue file is read from and work merges into.
    public let base: String
    /// The queue file's path inside the repository.
    public let queuePath: String

    /// A shift that drives `runner`, reading the queue file at `queuePath` on `base`.
    public init(runner: QueueRunner, base: String = "main", queuePath: String = "docs/queue.md") {
        self.runner = runner
        self.base = base
        self.queuePath = queuePath
    }

    /// One look at the queue: nil if Swift may not start (it has not heard you leave), else how the run went.
    public func tick() async throws -> QueueRun? {
        guard let presence = runner.presence, await presence.current == "away" else { return nil }
        let repository = runner.runner.repository
        let shown = try await Shell().run(["git", "show", "\(base):\(queuePath)"], in: repository)
        if shown.succeeded {
            try await QueueImport.add(QueueFile(text: shown.text),
                                      merged: try await QueueImport.merged(in: repository, base: base), to: runner.queue)
        }
        let run = try await runner.run()
        guard !run.outcomes.isEmpty else { return run }
        var states: [String: QueueState] = [:]
        for outcome in run.outcomes {
            states[outcome.task.id] = try await runner.queue.task(outcome.task.id)?.state
        }
        let report = SwiftReport(run: run, states: states, usage: try await usage(of: run))
        await runner.publish(report.event())
        return run
    }

    private func usage(of run: QueueRun) async throws -> ReportedUsage {
        let limits = try await runner.usageLog?.entries().last(where: { $0.limits != nil })?.limits
        let reserve = try await runner.budget?.reserve() ?? 0
        let cost = run.outcomes.compactMap(\.usage?.costUSD).reduce(0, +)
        return ReportedUsage(weekly: limits?.weekly ?? 0, fiveHour: limits?.fiveHour ?? 0, costUSD: cost, reserve: reserve)
    }
}
