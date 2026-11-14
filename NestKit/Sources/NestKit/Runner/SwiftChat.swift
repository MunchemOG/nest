import Foundation

/// Reads tasks out of what you tell Swift in chat, such as "Add a task: … Done means: …".
public enum SwiftChat {
    /// The task a message asks for, or nil if it is not adding a task.
    public static func task(in message: String) -> SwiftChatAsk? {
        let pattern = /(?i)^\s*add\s+(?:a\s+)?task\s*:?\s*(?<goal>.+?)(?:[.,;]?\s+done\s+means\s*:?\s*(?<test>.+?))?\s*\.?\s*$/
        guard let match = message.firstMatch(of: pattern) else { return nil }
        let goal = sentence(String(match.output.goal))
        guard let test = match.output.test.map({ sentence(String($0)) }), !test.isEmpty else { return .needsTest(goal: goal) }
        return .task(goal: goal, doneMeans: test)
    }

    /// The id for the next task you add: `Y-01`, then one past the highest `Y-` id already used.
    public static func nextID(after ids: [String]) -> String {
        let used = ids.compactMap { $0.firstMatch(of: /^Y-(\d+)$/).flatMap { Int($0.1) } }
        return "Y-" + String(format: "%02d", (used.max() ?? 0) + 1)
    }

    /// How a message asks its tasks to run, starting from `defaults`, or nil if it names no model, effort or subagents.
    public static func settings(in message: String, over defaults: RunSettings) -> RunSettings? {
        let text = message.lowercased()
        var settings = defaults
        var named = false
        let words = Set(text.split { !$0.isLetter }.map(String.init))
        if let model = ClaudeModel.allCases.first(where: { words.contains($0.rawValue) }) {
            settings.model = model
            named = true
        }
        let efforts: [(Regex<Substring>, Effort)] = [
            (/\bmax(?:imum)?\b/, .max), (/\b(?:x-?high|extra[ -]high)\b/, .xhigh), (/\bhigh effort\b/, .high),
            (/\b(?:medium|med) effort\b/, .medium), (/\blow effort\b/, .low),
        ]
        if let effort = efforts.first(where: { text.contains($0.0) }) {
            settings.effort = effort.1
            named = true
        }
        if text.contains(/\b(?:solo|one session|no (?:sub)?agents|without (?:sub)?agents)\b/) {
            settings.subagents = false
            named = true
        } else if text.contains(/\b(?:with|use|using) (?:sub)?agents\b/) {
            settings.subagents = true
            named = true
        }
        return named ? settings : nil
    }

    /// The task a message asks to run differently, such as "do Y-03 on opus", and the rest of the message.
    public static func retune(in message: String) -> (id: String, rest: String)? {
        guard let match = message.firstMatch(of: /(?i)^\s*(?:do|run)\s+([A-Z]+[0-9]*-\d+)\b(.*)$/) else { return nil }
        return (String(match.1).uppercased(), String(match.2))
    }

    private static func sentence(_ text: String) -> String {
        let trimmed = text.trimmingCharacters(in: .whitespaces.union(CharacterSet(charactersIn: ".")))
        return trimmed.prefix(1).uppercased() + trimmed.dropFirst()
    }
}
