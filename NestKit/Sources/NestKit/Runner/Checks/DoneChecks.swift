/// The checks a branch must pass, beyond its suite, before Swift believes it is done (see `docs/house-rules.md`).
public enum DoneChecks {
    /// Everything wrong with `diff`, one line each; empty when the branch passes.
    public static func problems(in diff: BranchDiff) -> [String] {
        TestWeakeningCheck.problems(in: diff)
            + RepositoryBoundsCheck.problems(in: diff)
            + DesignLiteralCheck.problems(in: diff)
            + UndoCheck.problems(in: diff)
    }
}
