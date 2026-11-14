import Foundation

/// Brings the tasks written in `docs/queue.md` into Swift's queue, so the queue file and the queue agree.
public enum QueueImport {
    /// Adds every task in `file` that `queue` does not hold yet, in the file's order; those in `merged` are added as done.
    /// Returns the ids added. A needs cell of `all` means every task written before it; words such as `Phase 1` add nothing.
    @discardableResult
    public static func add(_ file: QueueFile, merged: Set<String>, to queue: TaskQueue) async throws -> [String] {
        let held = Set(try await queue.tasks().map(\.id))
        var earlier: [String] = []
        var added: [String] = []
        for task in file.tasks {
            defer { earlier.append(task.id) }
            guard !held.contains(task.id) else { continue }
            try await queue.add(QueuedTask(
                id: task.id, goal: task.goal, doneMeans: task.doneMeans,
                needs: needs(task.needs, earlier: earlier), source: .you,
                state: merged.contains(task.id) ? .done : .queued
            ))
            added.append(task.id)
        }
        return added
    }

    /// The ids of the task branches merged into `base`, read from its merge commits.
    public static func merged(in repository: URL, base: String) async throws -> Set<String> {
        let output = try await Shell().run(["git", "log", base, "--merges", "--format=%s"], in: repository)
        guard output.succeeded else { throw ManualRunnerError.git(output.text) }
        return Set(output.text.split(separator: "\n").compactMap { subject in
            subject.firstMatch(of: /^Merge branch 'task\/([A-Z0-9]+-[0-9]+)'/).map { String($0.1) }
        })
    }

    private static func needs(_ cell: String, earlier: [String]) -> [String] {
        if cell.trimmingCharacters(in: .whitespaces) == "all" { return earlier }
        return cell.split(separator: ",")
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { $0.wholeMatch(of: /[A-Z0-9]+-[0-9]+/) != nil }
    }
}
