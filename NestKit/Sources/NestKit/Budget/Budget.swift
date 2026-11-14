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

    /// What a task is assumed to use of the weekly limit before the log has measured any.
    public static let firstGuess = 0.03

    /// A budget that keeps `rules`, reading `log`.
    public init(rules: BudgetRules, log: UsageLog, calendar: Calendar = .current, now: @escaping @Sendable () -> Date = { .now }) {
        self.rules = rules
        self.log = log
        self.calendar = calendar
        self.now = now
    }

    /// Whether the next task may start now.
    public func decide() async throws -> BudgetDecision {
        let time = now()
        let entries = try await log.entries()
        let report = UsageReport(entries: entries.filter { time.timeIntervalSince($0.started) <= 7 * 86_400 })
        let shares = report.tasks.map(\.weekly).filter { $0 > 0 }
        let nextTask = shares.isEmpty ? Self.firstGuess : shares.reduce(0, +) / Double(shares.count)
        return rules.decide(at: time, limits: entries.last(where: { $0.limits != nil })?.limits, nextTask: nextTask, calendar: calendar)
    }
}
