/// One section of a project's memory brief: a file in `.nest/memory/` and the paths it describes.
public struct MemorySection: Sendable, Equatable {
    /// The file's name without `.md`, such as `runner`.
    public let name: String
    /// The paths in the repository this section describes; a change to any of them can make it untrue.
    public let covers: [String]
    /// The section's text, front matter removed.
    public let body: String

    /// The section in `text`, a file named `name`.md that may start with front matter holding `covers: [a, b]`.
    public init(name: String, text: String) {
        self.name = name
        let lines = text.split(separator: "\n", omittingEmptySubsequences: false).map(String.init)
        guard lines.first == "---", let end = lines.dropFirst().firstIndex(of: "---") else {
            covers = []
            body = text
            return
        }
        let line = lines[1..<end].first { $0.hasPrefix("covers:") } ?? ""
        covers = line.dropFirst("covers:".count)
            .trimmingCharacters(in: .whitespaces.union(.init(charactersIn: "[]")))
            .split(separator: ",")
            .map { $0.trimmingCharacters(in: .whitespaces.union(.init(charactersIn: "\"'"))) }
            .filter { !$0.isEmpty }
        body = lines[(end + 1)...].joined(separator: "\n").trimmingCharacters(in: .newlines)
    }
}
