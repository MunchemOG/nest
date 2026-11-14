import Foundation

/// What Claude Code says about your usage: your plan, each limit with its reset, and what this session has done.
public struct ClaudeUsage: Sendable, Equatable {
    /// Your plan, such as `Pro`, if Claude Code said.
    public let plan: String?
    /// Your limits, in Claude Code's order: the session first, then the weeks.
    public let limits: [ClaudeLimit]
    /// What this session has cost, in US dollars.
    public let costUSD: Double
    /// Lines this session added.
    public let linesAdded: Int
    /// Lines this session removed.
    public let linesRemoved: Int

    /// A report with the given plan, limits and session totals.
    public init(plan: String?, limits: [ClaudeLimit], costUSD: Double = 0, linesAdded: Int = 0, linesRemoved: Int = 0) {
        self.plan = plan
        self.limits = limits
        self.costUSD = costUSD
        self.linesAdded = linesAdded
        self.linesRemoved = linesRemoved
    }

    /// The report in a `get_usage` response, or nil if it has no limits.
    init?(_ json: JSONValue) {
        guard let rates = json["rate_limits"] else { return nil }
        let limits = rates["limits"]?.array?.compactMap(ClaudeLimit.init) ?? []
        guard !limits.isEmpty else { return nil }
        self.limits = limits
        plan = json["subscription_type"]?.string.map { $0.prefix(1).uppercased() + $0.dropFirst() }
        costUSD = json["session"]?["total_cost_usd"]?.number ?? 0
        linesAdded = Int(json["session"]?["total_lines_added"]?.number ?? 0)
        linesRemoved = Int(json["session"]?["total_lines_removed"]?.number ?? 0)
    }

    /// The session and week as one snapshot, the shape Swift's limits and forecast use, if both have a reset.
    public var snapshot: LimitSnapshot? {
        guard let session = limits.first(where: { $0.title == "Session" }), let sessionResets = session.resets,
              let week = limits.first(where: { $0.title == "Week" }), let weekResets = week.resets else { return nil }
        return LimitSnapshot(fiveHour: session.used, fiveHourResets: sessionResets, weekly: week.used, weeklyResets: weekResets)
    }
}
