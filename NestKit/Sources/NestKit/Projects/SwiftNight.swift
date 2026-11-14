import Foundation

/// Swift working through every project you assigned, one after another, each in its own folder by its own rules,
/// under one budget: your caps, the learned forecast, and each project's share.
public struct SwiftNight: Sendable {
    /// Your limits and projects.
    public let settings: SwiftSettings
    /// Swift's own folder, where the queues and the usage log live.
    public let folder: URL
    /// The command that starts a Claude Code session; run settings and the prompt follow it.
    public let session: [String]
    /// Whether you are at the Mac.
    public let presence: PresenceWatch
    /// Where Swift's events go.
    public let publish: @Sendable (NestEvent) async -> Void
    /// The reserve kept back until the forecast has history.
    public let reserve: Double
    /// Called with each step and line, as they happen.
    public let watch: @Sendable (String) -> Void

    /// A night over `settings`' projects, keeping its queues in `folder`.
    public init(
        settings: SwiftSettings,
        folder: URL,
        session: [String],
        presence: PresenceWatch,
        publish: @escaping @Sendable (NestEvent) async -> Void = { _ in },
        reserve: Double = 0.25,
        watch: @escaping @Sendable (String) -> Void = { _ in }
    ) {
        self.settings = settings
        self.folder = folder
        self.session = session
        self.presence = presence
        self.publish = publish
        self.reserve = reserve
        self.watch = watch
    }

    /// One look at every project, in order; empty if Swift may not start. A project that fails is reported and the next goes on.
    public func tick() async -> [ProjectRun] {
        var runs: [ProjectRun] = []
        for project in settings.projects {
            do {
                let runner = try await runner(for: project)
                guard await presence.current == "away" else { return runs }
                try await ProjectMemory.keep(project, queue: runner.queue)
                let shift = SwiftShift(runner: runner, base: project.base,
                                       queuePath: project.importsQueueFile ? "docs/queue.md" : nil)
                guard let run = try await shift.tick() else { return runs }
                runs.append(ProjectRun(project: project.id, run: run, error: nil))
                if await presence.standsSwiftDown { return runs }
            } catch {
                runs.append(ProjectRun(project: project.id, run: nil, error: "\(error)"))
            }
        }
        return runs
    }

    /// The runner that builds `project`'s queue in its folder, by its rules, inside your limits.
    public func runner(for project: SwiftProject) async throws -> QueueRunner {
        let queueFile = project.queueFile(in: folder)
        try FileManager.default.createDirectory(at: queueFile.deletingLastPathComponent(), withIntermediateDirectories: true)
        let usage = try UsageLog(at: folder.appending(path: "usage.sqlite"))
        let tests = project.tests ?? []
        return QueueRunner(
            queue: try TaskQueue(at: queueFile),
            runner: ManualRunner(repository: project.url, session: session, tests: tests, base: project.base,
                                 defaults: project.defaults, checks: project.strictChecks,
                                 fallbackRules: SwiftProject.houseRules, watch: watch),
            merger: project.merges ? AutoMerge(repository: project.url, base: project.base) : nil,
            mainTests: project.merges ? tests : [],
            publish: publish,
            usageLog: usage,
            budget: Budget(rules: settings.limits.rules(reserve: reserve), log: usage,
                           forecast: UsageForecast(history: try await usage.yourUse()),
                           project: project.share.map { ProjectShare(project: project.id, share: $0) }),
            presence: presence,
            project: project.id
        )
    }
}
