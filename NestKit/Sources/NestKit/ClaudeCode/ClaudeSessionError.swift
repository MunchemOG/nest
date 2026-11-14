/// Why a session could not do what was asked.
public enum ClaudeSessionError: Error, Equatable {
    /// The session has not started, or has ended.
    case notStarted
}
