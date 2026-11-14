import Foundation
import NestKit
import Observation

/// Swift's cockpit: your projects and the one you're talking about, its chat and queue, your limits,
/// how its tasks run, and its memory. Every change you make is saved at once.
@MainActor
@Observable
final class SwiftPageModel {
    /// Where your limits and projects are saved, or nil to keep them only for this page.
    let store: SwiftSettingsStore?
    /// Swift's folder, where each project's queue lives, or nil when the page was given one queue.
    let folder: URL?
    /// The rules Swift kept before you set limits: the fixed reserve and the blocked hours.
    let rules: BudgetRules
    let log: UsageLog?
    /// Where your scheduled jobs are kept, or nil to keep them only for this page.
    let jobStore: JobStore?
    /// Claude Code's history, which your week is learned from, or nil to learn nothing.
    let history: ClaudeHistory?
    /// The Mac's active minutes, which your week is also learned from.
    let activityLog: ActivityLog?
    /// What turns a plain request into tasks for a project, or nil to only take tasks written out.
    let planner: @Sendable (SwiftProject) -> PlanPass?
    private let now: @Sendable () -> Date
    private var queues: [String: TaskQueue] = [:]

    /// Your limits and projects.
    private(set) var settings: SwiftSettings
    /// The id of the project you're talking about.
    private(set) var selected: String
    /// The chat so far, oldest first.
    private(set) var messages: [ChatMessage] = []
    /// Whether Swift is working out its reply.
    private(set) var isThinking = false
    /// The chosen project's tasks waiting or being built, in the order Swift will take them.
    private(set) var tonight: [QueuedTask] = []
    /// The Nest's autobuild queue: tasks waiting or being built, in order.
    private(set) var autobuild: [QueuedTask] = []
    /// The work you scheduled, in the order you added it.
    private(set) var jobs: [SwiftJob] = []
    /// When you work, learned from Claude Code's history.
    private(set) var pattern = WorkPattern(messages: [])
    /// The latest limits Claude reported, if any run was logged.
    private(set) var reported: LimitSnapshot?
    /// About how many more tasks fit this week under your cap, once a run is logged.
    private(set) var tasksLeft: Int?

    /// A page over one queue with fixed rules, and the Nest as its only project.
    init(queue: TaskQueue, rules: BudgetRules, log: UsageLog? = nil) {
        store = nil
        folder = nil
        jobStore = nil
        history = nil
        activityLog = nil
        self.rules = rules
        self.log = log
        planner = { _ in nil }
        now = { .now }
        let nest = SwiftProject.nest(at: URL(fileURLWithPath: "/"))
        settings = SwiftSettings(limits: SwiftLimits(weeklyCap: rules.weeklyCap, fiveHourCap: rules.fiveHourCeiling), projects: [nest])
        selected = nest.id
        queues[nest.id] = queue
    }

    /// A page over the settings in `store`, with each project's queue in `folder`.
    init(
        store: SwiftSettingsStore,
        folder: URL,
        log: UsageLog?,
        rules: BudgetRules = SwiftOnThisMac.rules,
        planner: @escaping @Sendable (SwiftProject) -> PlanPass? = { _ in nil },
        history: ClaudeHistory? = nil,
        now: @escaping @Sendable () -> Date = { .now }
    ) throws {
        self.store = store
        self.folder = folder
        jobStore = JobStore(at: folder.appending(path: "jobs.json"))
        self.history = history
        activityLog = ActivityLog(at: folder.appending(path: "activity.json"))
        self.rules = rules
        self.log = log
        self.planner = planner
        self.now = now
        let settings = try store.load()
        self.settings = settings
        selected = settings.projects.first?.id ?? "nest"
    }

    /// Where Swift keeps its queues, usage log and settings on this Mac.
    nonisolated static var folder: URL { URL.applicationSupportDirectory.appending(path: "Nest/Swift") }

    /// Swift's cockpit on this Mac, planning plain requests with Claude Code in each project's folder.
    static func onThisMac() throws -> SwiftPageModel {
        try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        return try SwiftPageModel(
            store: SwiftOnThisMac.settings(), folder: folder, log: try UsageLog(at: folder.appending(path: "usage.sqlite")),
            history: ClaudeHistory()
        )
    }

    // MARK: What you see

    /// Your projects, in the order Swift visits them.
    var projects: [SwiftProject] { settings.projects }
    /// The project you're talking about.
    var project: SwiftProject { settings.projects.first { $0.id == selected } ?? settings.projects[0] }
    /// The limits you set.
    var limits: SwiftLimits { settings.limits }
    /// The project Swift builds by itself from its queue file: the Nest.
    var nest: SwiftProject? { settings.projects.first { $0.importsQueueFile } }

    /// How much of the limits is used, in one line.
    var usage: String {
        guard let reported else { return "No runs logged yet." }
        return "\(Self.percent(reported.weekly)) of the week used · \(Self.percent(reported.fiveHour)) of the five hours"
    }

    /// What your cap buys this week, in one line.
    var tasksLeftLine: String {
        guard let tasksLeft else { return "No runs logged yet" }
        return tasksLeft == 1 ? "About 1 task left this week" : "About \(tasksLeft) tasks left this week"
    }

    /// How full the five-hour window is and when it resets, in one line.
    var fiveHourLine: String {
        guard let reported else { return "Limits show after Swift's first logged run." }
        let parts = Calendar.current.dateComponents([.hour, .minute], from: reported.fiveHourResets)
        return "Five hours: \(Self.percent(reported.fiveHour)) used, resets \(Self.clock((parts.hour ?? 0) * 60 + (parts.minute ?? 0)))"
    }

    /// `value` rounded to the nearest 5%, as the sliders set it.
    nonisolated static func step(_ value: Double) -> Double { (value * 20).rounded() / 20 }

    /// The chosen project's test command as you'd type it, or empty if it has none.
    var testsLine: String {
        guard let tests = project.tests else { return "" }
        return tests.count == 3 && tests[0] == "/bin/sh" && tests[1] == "-c" ? tests[2] : tests.joined(separator: " ")
    }

    /// What Swift keeps to, one line each.
    var boundaries: [String] {
        ["Keeps \(Self.percent(rules.reserve)) of the week back for you."]
            + (limits.weeklyCap < 1 ? ["Never uses more than \(Self.percent(limits.weeklyCap)) of the week."] : [])
            + rules.blocked.map { "Never runs in \($0.reason.lowercased()), \(Self.clock($0.from))–\(Self.clock($0.to))." }
            + ["Stands down when you arrive.", "Merges only when every test passes."]
    }

    // MARK: What you do

    /// Reads the chosen project's queue and the latest limits again.
    func refresh() async {
        tonight = ((try? await queue(for: project).tasks()) ?? []).filter { $0.state == .queued || $0.state == .claimed }
        reported = (try? await log?.entries())?.last(where: { $0.limits != nil })?.limits
        tasksLeft = await tasksLeft(underCap: nil)
        jobs = (try? jobStore?.load()) ?? jobs
        if let history {
            let activity = (try? activityLog?.hours()) ?? [:]
            pattern = await Task.detached { WorkPattern(messages: history.yourMessages(), activity: activity) }.value
        }
        if let nest {
            autobuild = ((try? await queue(for: nest).tasks()) ?? []).filter { $0.state == .queued || $0.state == .claimed }
        }
    }

    /// Talks about the project with id `id` from now on.
    func select(_ id: String) async {
        guard projects.contains(where: { $0.id == id }) else { return }
        selected = id
        await refresh()
    }

    /// Sends `text` to Swift about the chosen project and shows its reply.
    func send(_ text: String) async {
        messages.append(ChatMessage(id: UUID().uuidString, sender: .you, text: text))
        isThinking = true
        let project = project
        let reply: String
        do {
            reply = try await SwiftAsk(project: project, queue: queue(for: project), planner: planner(project)).answer(text)
        } catch {
            reply = "I couldn't do that: \(error.localizedDescription)"
        }
        isThinking = false
        say(reply)
        await refresh()
    }

    /// Schedules `job` and saves it.
    func addJob(_ job: SwiftJob) {
        jobs.append(job)
        try? jobStore?.save(jobs)
    }

    /// Removes the job with id `id`; its branch, if it ran, stays.
    func removeJob(_ id: String) {
        jobs.removeAll { $0.id == id }
        try? jobStore?.save(jobs)
    }

    /// When `job` runs next, as you'd say it, such as "Tonight 22:00" or "Wed 01:00".
    func whenLine(_ job: SwiftJob, now: Date = .now) -> String {
        guard let next = job.nextRun(after: now, pattern: pattern) else { return job.outcome ?? "Done" }
        let calendar = Calendar.current
        let time = next.formatted(date: .omitted, time: .shortened)
        if calendar.isDateInToday(next) { return next.timeIntervalSince(now) < 60 ? "Now" : "Today \(time)" }
        if calendar.isDateInTomorrow(next) { return "Tomorrow \(time)" }
        return next.formatted(.dateTime.weekday(.abbreviated)) + " " + time
    }

    /// Adds a task to the Nest's autobuild queue: "Add a task: … Done means: …".
    func queueForNest(_ text: String) async {
        guard let nest else { return }
        messages.append(ChatMessage(id: UUID().uuidString, sender: .you, text: text))
        let reply: String
        do {
            reply = try await SwiftAsk(project: nest, queue: queue(for: nest), planner: nil).answer(text)
        } catch {
            reply = "I couldn't queue that: \(error.localizedDescription)"
        }
        say(reply)
        await refresh()
    }

    /// Sets the model the Nest's autobuild runs on.
    func setAutobuildModel(_ model: ClaudeModel) { changeNest { $0.defaults.model = model } }
    /// Sets how hard the Nest's autobuild thinks.
    func setAutobuildEffort(_ effort: Effort) { changeNest { $0.defaults.effort = effort } }

    /// Adds the repository at `folder` as a project and talks about it.
    func addProject(at folder: URL) async {
        do {
            let added = try await SwiftProject.picked(folder, taken: projects.map(\.id))
            change { $0.projects.append(added) }
            say("Added \(added.name). Tell me what to build there.")
            await select(added.id)
        } catch {
            say("\(folder.lastPathComponent) isn't a git repository yet, so I can't work there safely. Run git init in it first.")
        }
    }

    /// Sets how much of the week Swift may use.
    func setWeeklyCap(_ cap: Double) async {
        change { $0.limits.weeklyCap = cap }
        tasksLeft = await tasksLeft(underCap: cap)
    }

    /// Sets how full the five-hour window may get.
    func setFiveHourCap(_ cap: Double) async {
        change { $0.limits.fiveHourCap = cap }
    }

    /// About how many tasks fit under `cap` (your cap when nil), for the preview while you drag.
    func tasksLeft(underCap cap: Double?) async -> Int? {
        guard let log else { return nil }
        let measured = (try? await log.entries())?.contains { $0.limits != nil } ?? false
        guard measured else { return nil }
        let budget = Budget(rules: limits.rules(reserve: rules.reserve, blocked: rules.blocked), log: log, now: now,
                            forecast: UsageForecast(history: (try? await log.yourUse()) ?? []))
        return try? await budget.tasksLeft(underCap: cap)
    }

    /// Sets the chosen project's share of your weekly cap; nil gives it no limit of its own.
    func setShare(_ share: Double?) { changeProject { $0.share = share } }
    /// Sets the model the chosen project's tasks run on.
    func setModel(_ model: ClaudeModel) { changeProject { $0.defaults.model = model } }
    /// Sets how hard the chosen project's tasks think.
    func setEffort(_ effort: Effort) { changeProject { $0.defaults.effort = effort } }
    /// Sets whether the chosen project's tasks may use subagents.
    func setSubagents(_ on: Bool) { changeProject { $0.defaults.subagents = on } }
    /// Sets whether green work merges by itself.
    func setAutoMerge(_ on: Bool) { changeProject { $0.autoMerge = on } }

    /// Sets the chosen project's test command, as you'd type it in Terminal; empty means it has no tests.
    func setTests(_ command: String) {
        let trimmed = command.trimmingCharacters(in: .whitespaces)
        changeProject { $0.tests = trimmed.isEmpty ? nil : ["/bin/sh", "-c", trimmed] }
    }

    /// Sets how one queued task runs; nil returns it to the project's default.
    func setRun(_ run: RunSettings?, for id: String) async {
        try? await queue(for: project).setRun(run, for: id)
        await refresh()
    }

    // MARK: Helpers

    private func queue(for project: SwiftProject) throws -> TaskQueue {
        if let queue = queues[project.id] { return queue }
        guard let folder else { throw CocoaError(.fileNoSuchFile) }
        let file = project.queueFile(in: folder)
        try FileManager.default.createDirectory(at: file.deletingLastPathComponent(), withIntermediateDirectories: true)
        let queue = try TaskQueue(at: file)
        queues[project.id] = queue
        return queue
    }

    private func say(_ text: String) {
        messages.append(ChatMessage(id: UUID().uuidString, sender: .bird(.swift), text: text))
    }

    private func change(_ edit: (inout SwiftSettings) -> Void) {
        edit(&settings)
        try? store?.save(settings)
    }

    private func changeNest(_ edit: (inout SwiftProject) -> Void) {
        guard let index = settings.projects.firstIndex(where: { $0.importsQueueFile }) else { return }
        change { edit(&$0.projects[index]) }
    }

    private func changeProject(_ edit: (inout SwiftProject) -> Void) {
        guard let index = settings.projects.firstIndex(where: { $0.id == selected }) else { return }
        change { edit(&$0.projects[index]) }
    }

    private static func percent(_ share: Double) -> String { "\(Int((share * 100).rounded()))%" }
    private static func clock(_ minutes: Int) -> String { String(format: "%02d:%02d", minutes / 60, minutes % 60) }
}
