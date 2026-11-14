/// One of Claude Code's slash commands, as the session lists them.
public struct SlashCommand: Sendable, Equatable, Hashable {
    /// Its name without the slash, such as `compact`.
    public let name: String
    /// What it does.
    public let description: String

    /// The command `name`, which does `description`.
    public init(name: String, description: String) {
        self.name = name
        self.description = description
    }
}
