/// How one turn of a session ended.
public struct SessionFinish: Sendable, Equatable {
    /// Claude Code's word for it, such as `success` or `error_during_execution`.
    public let subtype: String
    /// Whether it ended in an error, an interruption included.
    public let isError: Bool
    /// What the session has cost so far, in US dollars.
    public let costUSD: Double
    /// The session's id, for resuming it.
    public let sessionID: String?

    /// A finish with these fields.
    public init(subtype: String, isError: Bool, costUSD: Double, sessionID: String?) {
        self.subtype = subtype
        self.isError = isError
        self.costUSD = costUSD
        self.sessionID = sessionID
    }
}
