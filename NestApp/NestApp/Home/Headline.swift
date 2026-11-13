/// Home's one plain statement, the quieter line under it, and what needs you.
struct Headline: Hashable, Sendable {
    let main: String
    let sub: String
    let attention: String?

    init(facts: HeadlineFacts, waiting: Int) {
        var parts: [String] = []
        if let task = facts.building { parts.append("Swift is building \(task).") }
        if let until = facts.focusUntil, parts.count < 2 { parts.append("Wren is holding focus until \(until).") }
        if parts.count < 2 {
            if facts.inFlow {
                parts.append("You're in flow.")
            } else if facts.presence == "away" {
                parts.append("You're away.")
            }
        }
        main = parts.first ?? "All six are idle."
        sub = parts.dropFirst().first ?? ""
        attention = Self.attention(count: waiting)
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
