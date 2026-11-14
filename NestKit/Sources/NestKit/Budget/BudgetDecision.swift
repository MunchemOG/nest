/// Whether Swift may start the next task now.
public enum BudgetDecision: Sendable, Equatable {
    /// Go ahead.
    case run
    /// Wait; the text says why, in a sentence you can read.
    case pause(String)
}
