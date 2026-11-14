import Foundation

/// When you work, learned from all your work: the Mac's active minutes and your Claude Code messages over the last
/// four weeks, recent weeks counting most. Each weekday-and-hour slot gets a score; a slot scoring `threshold` or more
/// is yours and Swift leaves it alone. Every other hour is a gap Swift can work in.
public struct WorkPattern: Sendable, Equatable {
    /// Each hour of the week's score: `[weekday 1–7][hour 0–23]`, Sunday first.
    public let scores: [[Double]]
    /// The calendar weekdays and hours are read in.
    public let calendar: Calendar

    /// The score that makes an hour yours: more than any single week gives, so a one-off late night doesn't count.
    public static let threshold = 1.25
    /// How far back Swift learns from.
    public static let weeks = 4
    /// How much each week counts, newest first.
    public static let weights = [1.0, 0.75, 0.5, 0.25]
    /// The active minutes that make an hour on the Mac count as worked.
    public static let activeMinutes = 10

    /// The pattern in the messages you sent and the Mac's active minutes per hour, counting the four weeks before `now`.
    public init(messages: [Date], activity: [Date: Int] = [:], now: Date = .now, calendar: Calendar = .current) {
        self.calendar = calendar
        let worked = messages + activity.filter { $0.value >= Self.activeMinutes }.map(\.key)
        var hours: [DateComponents: Date] = [:]
        for time in worked where time <= now {
            hours[calendar.dateComponents([.year, .month, .day, .hour], from: time)] = time
        }
        var scores = Array(repeating: Array(repeating: 0.0, count: 24), count: 8)
        for time in hours.values {
            let age = Int(now.timeIntervalSince(time) / (7 * 86_400))
            guard age < Self.weeks else { continue }
            let parts = calendar.dateComponents([.weekday, .hour], from: time)
            scores[parts.weekday ?? 1][parts.hour ?? 0] += Self.weights[age]
        }
        self.scores = scores
    }

    /// The score of the hour `time` falls in.
    public func score(_ time: Date) -> Double {
        let parts = calendar.dateComponents([.weekday, .hour], from: time)
        return scores[parts.weekday ?? 1][parts.hour ?? 0]
    }

    /// Whether the hour `time` falls in is one you usually work in.
    public func isYours(_ time: Date) -> Bool { score(time) >= Self.threshold }

    /// Whether the hour `hour` on `weekday` (1 is Sunday) is one you usually work in.
    public func isYours(weekday: Int, hour: Int) -> Bool { scores[weekday][hour] >= Self.threshold }

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
