/// What one run of a scheduled job came to.
public struct JobResult: Sendable, Equatable {
    /// The branch its work is on.
    public let branch: String
    /// Claude's last words.
    public let summary: String
    /// What it cost, in US dollars.
    public let costUSD: Double
    /// The event that tells the flock, with the undo that deletes the branch.
    public let event: NestEvent
}
