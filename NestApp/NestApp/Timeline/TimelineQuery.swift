import Foundation
import NestKit

/// What the timeline shows: one bird or all, and words to look for.
struct TimelineQuery: Hashable, Sendable {
    /// Only this bird's rows, or everyone's when nil.
    var bird: Bird?
    /// Words to find in a row's sentence or details, such as a file name.
    var text = ""

    /// Whether `event` belongs in the timeline for this query.
    func matches(_ event: NestEvent) -> Bool {
        if let bird, event.sender != .bird(bird) { return false }
        let needle = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !needle.isEmpty else { return true }
        return event.summary.localizedStandardContains(needle)
            || event.data.values.contains { $0.contains(needle) }
    }

    /// The matching events, newest first, grouped by day in `timeZone`.
    static func groups(_ events: [NestEvent], matching query: TimelineQuery, in timeZone: TimeZone) -> [TimelineDay] {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = timeZone
        var days: [TimelineDay] = []
        for event in events.reversed() where query.matches(event) {
            let day = calendar.startOfDay(for: event.ts)
            if days.last?.day == day {
                days[days.count - 1].events.append(event)
            } else {
                days.append(TimelineDay(day: day, timeZone: timeZone, events: [event]))
            }
        }
        return days
    }
}

extension JSONValue {
    /// Whether any text inside this value contains `needle`, ignoring case.
    func contains(_ needle: String) -> Bool {
        switch self {
        case .string(let text): text.localizedStandardContains(needle)
        case .array(let values): values.contains { $0.contains(needle) }
        case .object(let values): values.values.contains { $0.contains(needle) }
        case .number, .bool, .null: false
        }
    }
}
