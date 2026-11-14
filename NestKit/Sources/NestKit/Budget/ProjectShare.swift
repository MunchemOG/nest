/// One project's share of the weekly cap you give Swift, so no project can use up the week.
public struct ProjectShare: Sendable, Equatable {
    /// The project's id.
    public let project: String
    /// Its share of your weekly cap (0 to 1).
    public let share: Double

    /// `project` may use `share` of your weekly cap.
    public init(project: String, share: Double) {
        self.project = project
        self.share = share
    }
}
