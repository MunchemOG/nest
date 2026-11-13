import Foundation

/// The summary block every session ends with, as `CLAUDE.md` lays it out.
public struct SummaryBlock: Sendable, Equatable {
    /// Whether the session says the task is done, held or unclear.
    public let result: SummaryResult
    /// One sentence on what the session did.
    public let did: String?
    /// Tests passed out of the total, and how many are new.
    public let tests: String?
    /// The files the session changed.
    public let files: String?
    /// Anything the session noticed outside the task.
    public let noticed: String?
    /// The next task and whether its needs are met.
    public let next: String?
    /// What failed, the session's best guess why, and how confident it is.
    public let ifHeld: String?

    /// The last summary block in `text`, or nil if there is none with a known result.
    public init?(in text: String) {
        let lines = text.components(separatedBy: .newlines).map { $0.trimmingCharacters(in: .whitespaces) }
        guard let start = lines.lastIndex(where: { $0.hasPrefix("Result:") }),
              let result = SummaryResult(rawValue: Self.value(of: lines[start]))
        else { return nil }

        var fields: [String: String] = [:]
        var current: String?
        for line in lines[(start + 1)...] {
            if line.isEmpty || line.hasPrefix("```") { break }
            if let key = Self.keys.first(where: { line.hasPrefix("\($0):") }) {
                fields[key] = Self.value(of: line)
                current = key
            } else if let current {
                fields[current] = [fields[current] ?? "", line].joined(separator: " ")
            }
        }

        self.result = result
        did = fields["Did"]
        tests = fields["Tests"]
        files = fields["Files"]
        noticed = fields["Noticed"]
        next = fields["Next"]
        ifHeld = fields["If held"]
    }

    private static let keys = ["Did", "Tests", "Files", "Noticed", "Next", "If held"]

    private static func value(of line: String) -> String {
        guard let colon = line.firstIndex(of: ":") else { return "" }
        return line[line.index(after: colon)...].trimmingCharacters(in: .whitespaces)
    }
}
