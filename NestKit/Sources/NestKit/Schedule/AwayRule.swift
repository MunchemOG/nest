import Foundation

/// How Swift decides by itself that you're away: idle a while in an hour you don't usually work, or idle a long while
/// at any time. Touching the Mac makes you here again. Holding Swift keeps you here.
public struct AwayRule: Sendable, Equatable {
    /// Idle this long in a gap and you're away.
    public let idleInGap: TimeInterval
    /// Idle this long at any time and you're away.
    public let idleAnyTime: TimeInterval

    /// A rule with these thresholds; by default 15 minutes in a gap, an hour any time.
    public init(idleInGap: TimeInterval = 15 * 60, idleAnyTime: TimeInterval = 60 * 60) {
        self.idleInGap = idleInGap
        self.idleAnyTime = idleAnyTime
    }

    /// `here` or `away`, after `idle` seconds without a key or click at `now`.
    public func presence(idle: TimeInterval, at now: Date, pattern: WorkPattern, hold: Bool) -> String {
        guard !hold else { return "here" }
        if idle >= idleAnyTime { return "away" }
        return idle >= idleInGap && !pattern.isYours(now) ? "away" : "here"
    }
}
