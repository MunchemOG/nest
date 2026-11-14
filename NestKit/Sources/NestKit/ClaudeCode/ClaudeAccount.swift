/// Who is signed in to Claude Code, as it says when it starts.
public struct ClaudeAccount: Sendable, Equatable {
    /// The account's email, if Claude Code said.
    public let email: String?
    /// The plan, such as `Claude Pro`, if Claude Code said.
    public let plan: String?

    /// The account `email` on `plan`.
    public init(email: String?, plan: String?) {
        self.email = email
        self.plan = plan
    }
}
