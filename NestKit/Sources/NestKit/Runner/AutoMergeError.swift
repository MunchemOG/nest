/// Why Swift did not merge or undo a task.
public enum AutoMergeError: Error, Equatable {
    /// The task did not end green, so it stays on its branch.
    case notGreen(String)
    /// The task's branch no longer merges cleanly; main was left as it was.
    case conflict(String)
    /// The event has no `git.revert` undo Swift can perform.
    case cannotUndo(String)
    /// A git command failed; the text is what git printed.
    case git(String)
}
