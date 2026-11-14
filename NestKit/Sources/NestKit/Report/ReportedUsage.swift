/// What a run used of the limits, for its report.
public struct ReportedUsage: Sendable, Equatable {
    /// Share of the weekly limit used so far (0 to 1).
    public let weekly: Double
    /// Share of the five-hour limit used so far (0 to 1).
    public let fiveHour: Double
    /// What the run's sessions cost, as Claude reported it, in US dollars.
    public let costUSD: Double
    /// The share of the weekly limit kept back for you (0 to 1).
    public let reserve: Double

    /// Usage with the given shares, cost and reserve.
    public init(weekly: Double, fiveHour: Double, costUSD: Double, reserve: Double) {
        self.weekly = weekly
        self.fiveHour = fiveHour
        self.costUSD = costUSD
        self.reserve = reserve
    }
}
