/// How one Claude Code session runs: its model, its effort, and whether it may split work across subagents.
public struct RunSettings: Sendable, Equatable, Hashable, Codable {
    /// The model the session runs on.
    public var model: ClaudeModel
    /// How hard it thinks.
    public var effort: Effort
    /// Whether it may hand parts of the work to subagents; off keeps everything in one session.
    public var subagents: Bool

    /// Settings for `model` at `effort`, with or without subagents.
    public init(model: ClaudeModel, effort: Effort, subagents: Bool) {
        self.model = model
        self.effort = effort
        self.subagents = subagents
    }

    /// The settings in a short form such as `opus/max/solo`, or nil if it is not one.
    public init?(code: String) {
        let parts = code.split(separator: "/").map(String.init)
        guard parts.count == 3, let model = ClaudeModel(rawValue: parts[0]), let effort = Effort(rawValue: parts[1]),
              parts[2] == "agents" || parts[2] == "solo" else { return nil }
        self.init(model: model, effort: effort, subagents: parts[2] == "agents")
    }

    /// The short form, such as `opus/max/solo`, as the queue keeps it.
    public var code: String { "\(model.rawValue)/\(effort.rawValue)/\(subagents ? "agents" : "solo")" }

    /// The arguments that start a Claude Code session this way.
    public var arguments: [String] {
        ["--model", model.rawValue, "--effort", effort.rawValue] + (subagents ? [] : ["--disallowed-tools", "Agent"])
    }

    /// What the session is told about splitting its work.
    public var promptLine: String {
        subagents
            ? "You may split independent parts of the work across subagents; check their results before you commit."
            : "Do all the work yourself in this one session; do not start subagents."
    }

    /// A one-line label such as "Opus · Max · solo".
    public var label: String { "\(model.name) · \(effort.name)\(subagents ? " · agents" : "")" }

    /// Swift's everyday default: Sonnet, high effort, one session.
    public static let everyday = RunSettings(model: .sonnet, effort: .high, subagents: false)
    /// The default for building a project's memory: the deepest model, as hard as it can, with subagents to read widely.
    public static let deepest = RunSettings(model: .opus, effort: .max, subagents: true)
}
