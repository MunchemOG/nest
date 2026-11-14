/// How one task in a run ended, as the report shows it.
public enum TaskEnding: String, Sendable, Equatable {
    /// Merged.
    case ok
    /// Held on its branch for you.
    case held
    /// Failed, or merged and rolled back.
    case fail
}
