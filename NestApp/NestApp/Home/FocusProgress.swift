import Foundation

/// How far through a timed mode you are.
struct FocusProgress: Hashable, Sendable {
    /// From 0 at the start to 1 at the end.
    let fraction: Double
    /// Whole minutes left.
    let minutesLeft: Int

    /// The progress from `since` to the time `until` ("15:30") on the same day, at `now`; nil if `until` can't be read.
    init?(since: Date, until: String, now: Date, timeZone: TimeZone) {
        let parts = until.split(separator: ":").compactMap { Int($0) }
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = timeZone
        guard parts.count == 2, let end = calendar.date(bySettingHour: parts[0], minute: parts[1], second: 0, of: since), end > since else { return nil }
        let total = end.timeIntervalSince(since)
        fraction = min(1, max(0, now.timeIntervalSince(since) / total))
        minutesLeft = max(0, Int((end.timeIntervalSince(now) / 60).rounded(.up)))
    }
}
