/// One task's share of the limits in a usage report.
public struct TaskUsage: Sendable, Equatable {
    /// The task.
    public let task: String
    /// What Claude reported it cost, in US dollars.
    public let costUSD: Double
    /// Its share of the weekly limit (0 to 1).
    public let weekly: Double
    /// Its share of the five-hour limit (0 to 1).
    public let fiveHour: Double
}
