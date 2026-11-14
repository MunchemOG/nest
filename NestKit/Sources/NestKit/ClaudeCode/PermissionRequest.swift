/// Claude Code asking whether it may use a tool.
public struct PermissionRequest: Sendable, Equatable, Hashable {
    /// The request's id, which the answer must carry.
    public let id: String
    /// The tool, such as `Bash` or `Write`.
    public let tool: String
    /// What the tool would be given.
    public let input: JSONValue
    /// Claude Code's own short description.
    public let description: String
    /// The rules Claude Code suggests for "always allow".
    public let suggestions: [JSONValue]

    /// A request with these fields.
    public init(id: String, tool: String, input: JSONValue, description: String, suggestions: [JSONValue]) {
        self.id = id
        self.tool = tool
        self.input = input
        self.description = description
        self.suggestions = suggestions
    }

    /// What it would do, in a few words: the command for Bash, else Claude Code's description.
    public var summary: String {
        if tool == "Bash", let command = input["command"]?.string { return command }
        return description.isEmpty ? ToolCard.summary(tool: tool, input: input, folder: "") : description
    }
}
