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

    /// What a task is assumed to use of the weekly limit before the log has measured any.
    public static let firstGuess = 0.03

    /// A budget that keeps `rules`, reading `log`.
    public init(
        rules: BudgetRules,
        log: UsageLog,
        calendar: Calendar = .current,
        now: @escaping @Sendable () -> Date = { .now },
        forecast: UsageForecast? = nil
    ) {
        self.rules = rules
        self.log = log
        self.calendar = calendar
        self.now = now
        self.forecast = forecast
    }

    /// Whether the next task may start now.
    public func decide() async throws -> BudgetDecision {
        let time = now()
        let entries = try await log.entries()
        let report = UsageReport(entries: entries.filter { time.timeIntervalSince($0.started) <= 7 * 86_400 })
        let shares = report.tasks.map(\.weekly).filter { $0 > 0 }
        let nextTask = shares.isEmpty ? Self.firstGuess : shares.reduce(0, +) / Double(shares.count)
        let limits = entries.last(where: { $0.limits != nil })?.limits
        let rules = BudgetRules(blocked: rules.blocked, reserve: reserve(at: time, limits: limits),
                                fiveHourCeiling: rules.fiveHourCeiling)
        return rules.decide(at: time, limits: limits, nextTask: nextTask, calendar: calendar)
    }

    /// The share of the weekly limit kept back for you now: the learned forecast once it has history, else the fixed reserve.
    public func reserve() async throws -> Double {
        reserve(at: now(), limits: try await log.entries().last(where: { $0.limits != nil })?.limits)
    }

    private func reserve(at time: Date, limits: LimitSnapshot?) -> Double {
        guard let forecast, let limits else { return rules.reserve }
        return forecast.reserve(from: time, until: limits.weeklyResets, orElse: rules.reserve)
    }
}
