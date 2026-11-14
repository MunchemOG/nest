import Foundation

/// One look at your scheduled jobs: while you're away and the budget allows, the first due job runs,
/// its run is recorded, and the flock hears where its work is.
public struct JobShift: Sendable {
    /// Where the jobs are kept.
    public let store: JobStore
    /// Your projects, to find each job's folder.
    public let projects: [SwiftProject]
    /// What runs a job.
    public let runner: JobRunner
    /// Whether you are at the Mac.
    public let presence: PresenceWatch
    /// When you work.
    public let pattern: WorkPattern
    /// Your limits, or nil to run without them.
    public let budget: Budget?
    /// Where Swift's events go.
    public let publish: @Sendable (NestEvent) async -> Void

    /// A shift over the jobs in `store`.
    public init(store: JobStore, projects: [SwiftProject], runner: JobRunner, presence: PresenceWatch, pattern: WorkPattern,
                budget: Budget?, publish: @escaping @Sendable (NestEvent) async -> Void = { _ in }) {
        self.store = store
        self.projects = projects
        self.runner = runner
        self.presence = presence
        self.pattern = pattern
        self.budget = budget
        self.publish = publish
    }

    /// Runs the first due job, if any may run now, and returns what came of it.
    @discardableResult
    public func tick(at now: Date = .now) async throws -> JobResult? {
        var jobs = try store.load()
        guard let job = JobRunner.next(jobs.filter { !$0.isFinished }, at: now, away: await presence.current == "away",
                                       pattern: pattern, calendar: pattern.calendar),
              let index = jobs.firstIndex(where: { $0.id == job.id }) else { return nil }
        if let budget, case .pause = try await budget.decide() { return nil }
        guard let project = projects.first(where: { $0.id == job.project }) else {
            jobs[index].lastRun = now
            jobs[index].outcome = "Its project is gone."
            try store.save(jobs)
            return nil
        }
        do {
            let result = try await runner.run(job, in: project.url, at: now)
            jobs[index].lastRun = now
            jobs[index].outcome = "On \(result.branch): \(result.summary.split(separator: "\n").first.map(String.init) ?? "")"
            try store.save(jobs)
            await publish(result.event)
            return result
        } catch {
            jobs[index].lastRun = now
            jobs[index].outcome = "Couldn't run: \(error)"
            try store.save(jobs)
            return nil
        }
    }
}
