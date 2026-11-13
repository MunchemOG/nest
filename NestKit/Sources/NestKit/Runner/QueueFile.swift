import Foundation

/// The tasks written as table rows in `docs/queue.md`.
public struct QueueFile: Sendable, Equatable {
    /// Every task in the file, in the order written.
    public let tasks: [QueueTask]

    /// The tasks in the queue file at `url`.
    public init(contentsOf url: URL) throws {
        self.init(text: try String(contentsOf: url, encoding: .utf8))
    }

    /// The tasks in `text`: each `| id | goal | done_means | needs |` row whose id looks like `S2-01`.
    public init(text: String) {
        tasks = text.split(separator: "\n").compactMap(Self.task)
    }

    /// The task with this id, if the file has one.
    public func task(_ id: String) -> QueueTask? {
        tasks.first { $0.id == id }
    }

    private static func task(row: Substring) -> QueueTask? {
        let line = row.trimmingCharacters(in: .whitespaces)
        guard line.hasPrefix("|"), line.hasSuffix("|") else { return nil }
        let cells = line.dropFirst().dropLast()
            .split(separator: "|", omittingEmptySubsequences: false)
            .map { $0.trimmingCharacters(in: .whitespaces) }
        guard cells.count == 4, cells[0].wholeMatch(of: /[A-Z0-9]+-[0-9]+/) != nil else { return nil }
        return QueueTask(id: cells[0], goal: cells[1], doneMeans: cells[2], needs: cells[3])
    }
}
