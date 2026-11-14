/// A Claude model Swift can run a session on, named by its Claude Code `--model` alias.
public enum ClaudeModel: String, Sendable, Equatable, CaseIterable, Codable {
    /// The fastest and cheapest.
    case haiku
    /// The everyday builder.
    case sonnet
    /// Deep work.
    case opus
    /// The newest family.
    case fable

    /// The model's name as you see it.
    public var name: String { rawValue.prefix(1).uppercased() + rawValue.dropFirst() }
}
