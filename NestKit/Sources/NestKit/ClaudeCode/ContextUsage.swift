/// How full a session's context is, as Claude Code reports it.
public struct ContextUsage: Sendable, Equatable {
    /// Tokens in the context now.
    public let usedTokens: Int
    /// The most the context holds.
    public let maxTokens: Int
    /// Where Claude Code compacts the session, or nil if it doesn't on its own.
    public let compactsAt: Int?

    /// A context holding `usedTokens` of `maxTokens`, compacting at `compactsAt`.
    public init(usedTokens: Int, maxTokens: Int, compactsAt: Int?) {
        self.usedTokens = usedTokens
        self.maxTokens = maxTokens
        self.compactsAt = compactsAt
    }

    /// The context in a `get_context_usage` response, or nil if it has none.
    init?(_ json: JSONValue) {
        guard let used = json["totalTokens"]?.number, let max = json["maxTokens"]?.number, max > 0 else { return nil }
        usedTokens = Int(used)
        maxTokens = Int(max)
        compactsAt = json["isAutoCompactEnabled"] == .bool(false) ? nil : json["autoCompactThreshold"]?.number.map { Int($0) }
    }

    /// Share of the context used (0 is empty, 1 is full).
    public var used: Double { Double(usedTokens) / Double(maxTokens) }
}
