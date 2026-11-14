/// Hours Swift never runs in, kept free for you, such as robotics practice.
public struct BlockedHours: Sendable, Equatable {
    /// The days it applies to, as `Calendar` weekdays (1 is Sunday, 7 is Saturday).
    public let weekdays: Set<Int>
    /// When it starts, in minutes after midnight.
    public let from: Int
    /// When it ends, in minutes after midnight; that minute is free again.
    public let to: Int
    /// What you are doing then, such as "Robotics hours".
    public let reason: String

    /// Blocks `from` to `to` (minutes after midnight) on `weekdays`, for `reason`.
    public init(weekdays: Set<Int>, from: Int, to: Int, reason: String) {
        self.weekdays = weekdays
        self.from = from
        self.to = to
        self.reason = reason
    }

    /// Whether the minute `minute` after midnight on `weekday` is blocked.
    public func contains(weekday: Int, minute: Int) -> Bool {
        weekdays.contains(weekday) && minute >= from && minute < to
    }
}
