/// Why a plan-mode answer could not be queued.
public enum PlanPassError: Error, Equatable {
    /// The answer held neither task rows nor a reason to drop the idea.
    case noPlan
    /// A task row had no "done means" test.
    case taskWithoutTest(String)
    /// The plan-mode session failed; the text is what it printed.
    case sessionFailed(String)
}
