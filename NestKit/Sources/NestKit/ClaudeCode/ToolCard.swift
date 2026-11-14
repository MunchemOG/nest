/// One tool Claude used, as the transcript shows it: what it touched, what changed, and how it went.
public struct ToolCard: Sendable, Equatable {
    /// How a tool call stands.
    public enum Status: Sendable, Equatable {
        /// Still running.
        case running
        /// Finished.
        case done
        /// Failed or was refused.
        case failed
    }

    /// The tool call's id.
    public let id: String
    /// The tool, such as `Edit`.
    public let name: String
    /// What it touched, in a few words.
    public let summary: String
    /// The change or command in full, such as an edit's lines.
    public let detail: String
    /// What it gave back.
    public var result: String?
    /// How it stands.
    public var status: Status

    /// A card for a call that has just started.
    public init(id: String, name: String, summary: String, detail: String, result: String? = nil, status: Status = .running) {
        self.id = id
        self.name = name
        self.summary = summary
        self.detail = detail
        self.result = result
        self.status = status
    }

    /// What a call to `tool` with `input` touches, with paths shown inside `folder`.
    public static func summary(tool: String, input: JSONValue, folder: String) -> String {
        let keys = ["file_path", "notebook_path", "path", "command", "pattern", "url", "query", "description", "prompt"]
        guard let value = keys.lazy.compactMap({ input[$0]?.string }).first else { return "" }
        let prefix = folder.hasSuffix("/") ? folder : folder + "/"
        let line = value.split(separator: "\n").first.map(String.init) ?? value
        return !folder.isEmpty && line.hasPrefix(prefix) ? String(line.dropFirst(prefix.count)) : line
    }

    /// The change a call makes, in full: removed and added lines for an edit, the command for Bash, the text for a write.
    public static func detail(tool: String, input: JSONValue) -> String {
        if let old = input["old_string"]?.string, let new = input["new_string"]?.string {
            let lines = { (text: String, mark: String) in text.split(separator: "\n", omittingEmptySubsequences: false).map { "\(mark) \($0)" } }
            return (lines(old, "-") + lines(new, "+")).joined(separator: "\n")
        }
        return input["command"]?.string ?? input["content"]?.string ?? ""
    }
}
