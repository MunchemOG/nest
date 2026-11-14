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

    private static func sentence(_ text: String) -> String {
        let trimmed = text.trimmingCharacters(in: .whitespaces.union(CharacterSet(charactersIn: ".")))
        return trimmed.prefix(1).uppercased() + trimmed.dropFirst()
    }
}
