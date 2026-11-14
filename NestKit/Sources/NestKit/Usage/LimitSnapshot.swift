import Foundation

/// How much of the Pro plan's two limits was used at one moment, as Claude reports it (0 is none, 1 is all).
public struct LimitSnapshot: Sendable, Equatable {
    /// Share of the five-hour limit used.
    public let fiveHour: Double
    /// When the five-hour window resets.
    public let fiveHourResets: Date
    /// Share of the weekly limit used.
    public let weekly: Double
    /// When the weekly window resets.
    public let weeklyResets: Date

    /// A snapshot with the given shares and reset times.
    public init(fiveHour: Double, fiveHourResets: Date, weekly: Double, weeklyResets: Date) {
        self.fiveHour = fiveHour
        self.fiveHourResets = fiveHourResets
        self.weekly = weekly
        self.weeklyResets = weeklyResets
    }

    /// What was used between `earlier` and this snapshot in one window: the rise, or everything since a reset.
    static func used(from earlier: Double, earlierResets: Date, to later: Double, laterResets: Date) -> Double {
        earlierResets == laterResets ? max(0, later - earlier) : later
    }
}
