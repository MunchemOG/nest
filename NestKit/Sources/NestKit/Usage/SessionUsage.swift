import Foundation

/// What one Claude Code session cost, read from its `--output-format stream-json` output.
public struct SessionUsage: Sendable, Equatable {
    /// The cost Claude reports for the session, in US dollars.
    public let costUSD: Double
    /// Tokens read, counting cached and newly cached input.
    public let inputTokens: Int
    /// Tokens written.
    public let outputTokens: Int
    /// The models the session used.
    public let models: [String]
    /// The limits as they stood during the session, if Claude reported them.
    public let limits: LimitSnapshot?
    /// The session's final answer, where its summary block is.
    public let text: String

    /// The usage in a session's stream-json output, or nil if the output has no result line.
    public init?(output: String) {
        var limits: LimitSnapshot?
        var result: [String: Any]?
        for line in output.split(separator: "\n") where line.hasPrefix("{") {
            guard let object = try? JSONSerialization.jsonObject(with: Data(line.utf8)) as? [String: Any] else { continue }
            switch object["type"] as? String {
            case "rate_limit_event": limits = Self.limits(in: object) ?? limits
            case "result": result = object
            default: break
            }
        }
        guard let result, let cost = result["total_cost_usd"] as? Double else { return nil }
        let usage = result["usage"] as? [String: Any] ?? [:]
        let count = { (key: String) in usage[key] as? Int ?? 0 }
        costUSD = cost
        inputTokens = count("input_tokens") + count("cache_read_input_tokens") + count("cache_creation_input_tokens")
        outputTokens = count("output_tokens")
        models = (result["modelUsage"] as? [String: Any] ?? [:]).keys.sorted()
        self.limits = limits
        text = result["result"] as? String ?? ""
    }

    private static func limits(in event: [String: Any]) -> LimitSnapshot? {
        let windows = (event["rate_limit_info"] as? [String: Any])?["unifiedWindows"] as? [String: Any]
        guard let five = windows?["five_hour"] as? [String: Any], let week = windows?["seven_day"] as? [String: Any],
              let fiveUsed = five["utilization"] as? Double, let weekUsed = week["utilization"] as? Double,
              let fiveResets = five["resetsAt"] as? Double, let weekResets = week["resetsAt"] as? Double else { return nil }
        return LimitSnapshot(fiveHour: fiveUsed, fiveHourResets: Date(timeIntervalSince1970: fiveResets),
                             weekly: weekUsed, weeklyResets: Date(timeIntervalSince1970: weekResets))
    }
}
