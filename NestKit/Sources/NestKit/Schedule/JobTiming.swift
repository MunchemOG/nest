import Foundation

/// When a scheduled job runs.
public enum JobTiming: Sendable, Equatable, Hashable, Codable {
    /// The next hour you don't usually work in.
    case nextGap
    /// Tonight: from 22:00 on the day it was scheduled, in a gap.
    case tonight
    /// At a time you picked.
    case at(Date)
    /// Every night, in a gap within `window` hours of `hour`.
    case nightly(hour: Int)
    /// Every week on `weekday` (1 is Sunday), in a gap within `window` hours of `hour`.
    case weekly(weekday: Int, hour: Int)

    /// When "tonight" starts.
    public static let tonightHour = 22
    /// How many hours after its set hour a repeating job may still start.
    public static let window = 6

    /// Whether the job repeats.
    public var repeats: Bool {
        switch self {
        case .nightly, .weekly: true
        default: false
        }
    }
}
