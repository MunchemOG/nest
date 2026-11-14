/// How one project's part of a night went: its run, or the error that stopped it.
public struct ProjectRun: Sendable {
    /// The project's id.
    public let project: String
    /// The run, if it got going.
    public let run: QueueRun?
    /// What stopped it, if anything did.
    public let error: String?
}
