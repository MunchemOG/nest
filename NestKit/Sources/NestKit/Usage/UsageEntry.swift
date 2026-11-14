import Foundation

/// One of Swift's sessions in the usage log.
public struct UsageEntry: Sendable, Equatable {
    /// The task the session built.
    public let task: String
    /// When the session started.
    public let started: Date
    /// When it ended.
    public let ended: Date
    /// What Claude reported it cost, in US dollars.
    public let costUSD: Double
    /// The limits as they stood during the session.
    public let limits: LimitSnapshot?

    /// An entry with the given fields.
    public init(task: String, started: Date, ended: Date, costUSD: Double, limits: LimitSnapshot?) {
        self.task = task
        self.started = started
        self.ended = ended
        self.costUSD = costUSD
        self.limits = limits
    }
}
