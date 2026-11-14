import Foundation

/// When you work, learned from when you talk to Claude Code: an hour of the week you've worked in at least twice
/// in the last four weeks is yours, and Swift leaves it alone. Every other hour is a gap Swift can work in.
public struct WorkPattern: Sendable, Equatable {
    /// How many times you worked in each hour of the week: `[weekday 1–7][hour 0–23]`, Sunday first.
    public let counts: [[Int]]
    /// The calendar weekdays and hours are read in.
    public let calendar: Calendar

    /// How many of the last four weeks an hour must have been worked in to be yours.
    public static let threshold = 2
    /// How far back Swift learns from.
    public static let weeks = 4

    /// The pattern in the messages you sent, counting only the four weeks before `now`.
    public init(messages: [Date], now: Date = .now, calendar: Calendar = .current) {
        self.calendar = calendar
        let start = calendar.date(byAdding: .day, value: -7 * Self.weeks, to: now) ?? now
        var hours = Set<DateComponents>()
        for time in messages where time >= start && time <= now {
            hours.insert(calendar.dateComponents([.year, .month, .day, .hour, .weekday], from: time))
        }
        var counts = Array(repeating: Array(repeating: 0, count: 24), count: 8)
        for hour in hours {
            if let weekday = hour.weekday, let clock = hour.hour { counts[weekday][clock] += 1 }
        }
        self.counts = counts
    }

    /// Whether the hour `time` falls in is one you usually work in.
    public func isYours(_ time: Date) -> Bool {
        let parts = calendar.dateComponents([.weekday, .hour], from: time)
        return counts[parts.weekday ?? 1][parts.hour ?? 0] >= Self.threshold
    }

    /// `time` itself if it's a gap, else the start of the next hour that is; nil if the whole next week is yours.
    public func nextGap(after time: Date) -> Date? {
        if !isYours(time) { return time }
        guard var hour = calendar.dateInterval(of: .hour, for: time)?.start else { return nil }
        for _ in 0..<(24 * 7) {
            guard let next = calendar.date(byAdding: .hour, value: 1, to: hour) else { return nil }
            hour = next
            if !isYours(hour) { return hour }
        }
        return nil
    }
}
