import Foundation

/// How much of the weekly limit you used yourself on one day (0 to 1).
public struct DayUse: Sendable, Equatable {
    /// The day.
    public let day: Date
    /// Your share of the weekly limit that day.
    public let used: Double

    /// A day's use.
    public init(day: Date, used: Double) {
        self.day = day
        self.used = used
    }
}
