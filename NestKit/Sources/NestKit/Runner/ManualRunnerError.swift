/// Why the manual runner refused to start or could not carry on.
public enum ManualRunnerError: Error, Equatable {
    /// Tracked files have changes that are not committed; the runner will not switch branches over them.
    case uncommittedChanges
    /// A git command failed; the text is what git printed.
    case git(String)
}
