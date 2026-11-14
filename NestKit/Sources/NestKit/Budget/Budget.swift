import Foundation

/// Swift's budget at run time: the rules, checked against the latest limits and tasks' recent cost in the usage log.
public struct Budget: Sendable {
    /// The rules to keep.
    public let rules: BudgetRules
    /// Where the latest limits and recent task costs come from.
    public let log: UsageLog
    /// The calendar blocked hours are read in.
    public let calendar: Calendar
    /// The time now.
    public let now: @Sendable () -> Date
    /// Your learned use, which replaces the rules' fixed reserve once it has history; nil keeps the fixed reserve.
    public let forecast: UsageForecast?
    /// The project this budget runs, and its share of your cap; nil runs without a share.
    public let project: ProjectShare?

    /// What a task is assumed to use of the weekly limit before the log has measured any.
    public static let firstGuess = 0.03

    /// A budget that keeps `rules`, reading `log`.
    public init(
        rules: BudgetRules,
        log: UsageLog,
        calendar: Calendar = .current,
        now: @escaping @Sendable () -> Date = { .now },
        forecast: UsageForecast? = nil,
        project: ProjectShare? = nil
    ) {
        self.rules = rules
        self.log = log
        self.calendar = calendar
        self.now = now
        self.forecast = forecast
        self.project = project
    }

    /// Whether the next task may start now.
    public func decide() async throws -> BudgetDecision {
        let week = try await thisWeek()
        let decision = week.rules.decide(at: week.time, limits: week.limits, nextTask: week.nextTask, calendar: calendar)
        guard decision == .run, let project else { return decision }
        let used = zip(week.entries, week.report.tasks).filter { $0.0.project == project.project }.map(\.1.weekly).reduce(0, +)
        let allowed = project.share * rules.weeklyCap
        guard used + week.nextTask > allowed + 1e-9 else { return .run }
        return .pause("\(project.project) has used its share: \(Self.percent(used)) of the week, the next task needs about "
                      + "\(Self.percent(week.nextTask)), and its share is \(Self.percent(allowed)).")
    }

    /// About how many more tasks fit this week under `cap` (your cap when nil), at the recent cost of a task.
    public func tasksLeft(underCap cap: Double? = nil) async throws -> Int {
        let week = try await thisWeek()
        let ceiling = min(cap ?? rules.weeklyCap, 1 - week.rules.reserve)
        let room = ceiling - (week.limits?.weekly ?? 0)
        return max(0, Int((room / week.nextTask + 1e-9).rounded(.down)))
    }

    private func thisWeek() async throws -> Week {
        let time = now()
        let entries = try await log.entries().filter { time.timeIntervalSince($0.started) <= 7 * 86_400 }
        let report = UsageReport(entries: entries)
        let shares = report.tasks.map(\.weekly).filter { $0 > 0 }
        let nextTask = shares.isEmpty ? Self.firstGuess : shares.reduce(0, +) / Double(shares.count)
        let limits = try await log.entries().last(where: { $0.limits != nil })?.limits
        let rules = BudgetRules(blocked: rules.blocked, reserve: reserve(at: time, limits: limits),
                                fiveHourCeiling: rules.fiveHourCeiling, weeklyCap: rules.weeklyCap)
        return Week(time: time, entries: entries, report: report, nextTask: nextTask, limits: limits, rules: rules)
    }

    private struct Week {
        let time: Date
        let entries: [UsageEntry]
        let report: UsageReport
        let nextTask: Double
        let limits: LimitSnapshot?
        let rules: BudgetRules
    }

    private static func percent(_ share: Double) -> String { "\(Int((share * 100).rounded()))%" }

    /// The share of the weekly limit kept back for you now: the learned forecast once it has history, else the fixed reserve.
    public func reserve() async throws -> Double {
        reserve(at: now(), limits: try await log.entries().last(where: { $0.limits != nil })?.limits)
    }

    private func reserve(at time: Date, limits: LimitSnapshot?) -> Double {
        guard let forecast, let limits else { return rules.reserve }
        return forecast.reserve(from: time, until: limits.weeklyResets, orElse: rules.reserve)
    }
}
