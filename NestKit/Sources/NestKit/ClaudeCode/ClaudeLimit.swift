import Foundation

/// One of your plan's limits as Claude Code reports it: the session, the week, or one model's week.
public struct ClaudeLimit: Sendable, Equatable {
    /// The limit's name as you see it, such as `Session` or `Fable's week`.
    public let title: String
    /// Share used (0 is none, 1 is all).
    public let used: Double
    /// When it resets, if Claude Code said.
    public let resets: Date?
    /// Whether Claude Code flags it as nearly used up.
    public let isCritical: Bool

    /// A limit named `title`, `used` full, resetting at `resets`.
    public init(title: String, used: Double, resets: Date?, isCritical: Bool) {
        self.title = title
        self.used = used
        self.resets = resets
        self.isCritical = isCritical
    }

    /// The limit in one entry of `get_usage`'s `limits`, or nil if it has no share.
    init?(_ json: JSONValue) {
        guard let percent = json["percent"]?.number else { return nil }
        let model = json["scope"]?["model"]?["display_name"]?.string
        switch json["kind"]?.string {
        case "session": title = "Session"
        case "weekly_all": title = "Week"
        default: title = model.map { "\($0)'s week" } ?? "Week"
        }
        used = percent / 100
        resets = json["resets_at"]?.string.flatMap(Self.date)
        isCritical = json["severity"]?.string == "critical"
    }

    /// The moment in an ISO 8601 `text` such as `2026-11-15T02:39:59.518312+00:00`, to the second.
    static func date(_ text: String) -> Date? {
        let whole = text.replacingOccurrences(of: #"\.\d+"#, with: "", options: .regularExpression)
        return try? Date(whole, strategy: .iso8601)
    }
}
