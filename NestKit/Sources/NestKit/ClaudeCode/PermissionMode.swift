/// How Claude Code asks before it acts, as its `--permission-mode` takes it.
public enum PermissionMode: String, Sendable, Equatable, CaseIterable, Codable {
    /// Asks before edits and commands.
    case ask = "default"
    /// Edits files without asking; still asks before commands.
    case acceptEdits
    /// Reads and plans; changes nothing.
    case plan
    /// Never asks.
    case auto = "bypassPermissions"

    /// The mode's name as you see it.
    public var name: String {
        switch self {
        case .ask: "Ask"
        case .acceptEdits: "Accept edits"
        case .plan: "Plan"
        case .auto: "Auto"
        }
    }
}
