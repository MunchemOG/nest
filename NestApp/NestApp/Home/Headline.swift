import Foundation

/// Home's one plain statement, the quieter line under it, and what needs you.
struct Headline: Hashable, Sendable {
    let main: String
    let sub: String
    let attention: String?

    init(facts: HeadlineFacts, waiting: Int, now: Date? = nil) {
        var parts: [String] = []
        if let task = facts.building { parts.append("Swift is building \(task).") }
        if let until = facts.focusUntil, parts.count < 2 { parts.append("Wren is holding focus until \(until).") }
        if parts.count < 2 {
            if facts.inFlow {
                if let since = facts.flowSince, let now {
                    parts.append("You've been in flow for \(Self.duration(now.timeIntervalSince(since))).")
                } else {
                    parts.append("You're in flow.")
                }
            } else if facts.presence == "away" {
                parts.append("You're away.")
            }
        }
        main = parts.first ?? "All six are idle."
        sub = parts.dropFirst().first ?? ""
        attention = Self.attention(count: waiting)
    }

    /// "1 h 35 min", or "40 min" under an hour.
    static func duration(_ seconds: TimeInterval) -> String {
        let minutes = max(0, Int(seconds / 60))
        return minutes < 60 ? "\(minutes) min" : "\(minutes / 60) h \(minutes % 60) min"
    }

    /// "Two things need you", or nil when nothing does.
    static func attention(count: Int) -> String? {
        switch count {
        case 0: nil
        case 1: "One thing needs you"
        case 2: "Two things need you"
        default: "\(count) things need you"
        }
    }
}
