import Foundation
import NestKit

/// Lets the demo day start part-way through (`-NestReplayStart 15:16`), for demos and screenshots.
enum DemoReplayStart {
    /// The moment the replay starts from: `time` on the day's date, or the first event's time.
    static func start(_ events: [NestEvent], at time: String?, in timeZone: TimeZone = .current) -> Date? {
        let (past, future) = split(events, at: time, in: timeZone)
        guard !past.isEmpty, let parts = time?.split(separator: ":").compactMap({ Int($0) }), parts.count == 2, let first = events.first else {
            return future.first?.ts
        }
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = timeZone
        return calendar.date(bySettingHour: parts[0], minute: parts[1], second: 0, of: first.ts)
    }

    /// The events before `time` ("HH:mm" on the clock the app shows times in), and the rest; with no time, nothing is skipped.
    static func split(_ events: [NestEvent], at time: String?, in timeZone: TimeZone = .current) -> (past: [NestEvent], future: [NestEvent]) {
        let parts = time?.split(separator: ":").compactMap { Int($0) } ?? []
        guard parts.count == 2, let first = events.first else { return ([], events) }
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = timeZone
        guard let cut = calendar.date(bySettingHour: parts[0], minute: parts[1], second: 0, of: first.ts) else { return ([], events) }
        let index = events.firstIndex { $0.ts >= cut } ?? events.count
        return (Array(events[..<index]), Array(events[index...]))
    }
}
