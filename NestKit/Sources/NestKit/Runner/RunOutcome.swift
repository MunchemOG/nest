/// How one run of the manual runner ended.
public struct RunOutcome: Sendable, Equatable {
    /// The task that ran.
    public let task: QueueTask
    /// The branch the work is on.
    public let branch: String
    /// The summary block the session ended with, if it wrote one.
    public let summary: SummaryBlock?
    /// Whether the suite passed when the runner ran it itself.
    public let testsPassed: Bool
    /// Why the task is held, or nil when it is done.
    public let held: String?

    /// Whether the task is done: on its branch, summary block read, suite green.
    public var isDone: Bool { held == nil }
}
