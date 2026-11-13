import Foundation

/// Merges green task branches with no help, leaving a restore point first, and undoes a merge in one step.
public struct AutoMerge: Sendable {
    /// The repository the tasks are built in.
    public let repository: URL
    /// The branch tasks merge into.
    public let base: String

    private let shell = Shell()

    /// A merger for `repository` that merges into `base`.
    public init(repository: URL, base: String = "main") {
        self.repository = repository
        self.base = base
    }

    /// The tag that marks where `base` stood just before `task` merged.
    public static func restorePoint(for task: String) -> String { "nest/restore/\(task)" }

    /// Merges a green task into the base branch, tagging a restore point first, and returns the `swift.task.merged` event.
    public func merge(_ outcome: RunOutcome, at time: Date = .now) async throws -> NestEvent {
        let id = outcome.task.id
        guard outcome.isDone, outcome.testsPassed else { throw AutoMergeError.notGreen(id) }
        try await git("switch", "-q", base)
        try await git("tag", "-f", Self.restorePoint(for: id), "HEAD")
        let merged = try await shell.run(["git", "merge", "-q", "--no-ff", outcome.branch, "-m", "Merge branch '\(outcome.branch)'"],
                                         in: repository)
        guard merged.succeeded else {
            _ = try await shell.run(["git", "merge", "--abort"], in: repository)
            _ = try await shell.run(["git", "tag", "-d", Self.restorePoint(for: id)], in: repository)
            throw AutoMergeError.conflict(id)
        }
        return Self.mergedEvent(task: id, goal: outcome.task.goal, commit: try await git("rev-parse", "HEAD"),
                                testsAdded: Self.testsAdded(from: outcome.summary?.tests), at: time, again: false)
    }

    /// Performs `event`'s undo: reverts the merge it made, or, for an undo, reverts that revert (Redo). Returns the new event,
    /// which carries `why` and reaches you as far as `attention` says.
    public func undo(
        _ event: NestEvent,
        why: String = "You asked to undo it.",
        attention: EventAttention = .none,
        at time: Date = .now
    ) async throws -> NestEvent {
        guard let undo = event.undo, undo.op == "git.revert", case .string(let commit)? = undo.args["commit"] else {
            throw AutoMergeError.cannotUndo(event.id)
        }
        try await git("switch", "-q", base)
        let isMerge = try await git("rev-list", "--parents", "-n", "1", commit).split(separator: " ").count > 2
        try await git(arguments: ["revert", "--no-edit"] + (isMerge ? ["-m", "1"] : []) + [commit])
        let revert = try await git("rev-parse", "HEAD")
        if event.kind == .undo {
            let original = try await git("log", "-1", "--format=%B", commit)
                .firstMatch(of: /This reverts commit ([0-9a-f]+)/).map { String($0.1) } ?? commit
            let task = try await taskID(ofMerge: original)
            return Self.mergedEvent(task: task, goal: nil, commit: revert, testsAdded: 0, at: time, again: true)
        }
        let task = event.data["task"].flatMap { if case .string(let id) = $0 { id } else { nil } } ?? commit
        return NestEvent(
            id: EventID.make(at: time), ts: time, sender: .bird(.swift), kind: .undo, topic: .swiftMergeRolledBack,
            summary: "Swift undid the merge of \(task)",
            data: ["target": .string(event.id), "why": .string(why)],
            undo: EventUndo(op: "git.revert", args: ["commit": .string(revert)]),
            causedBy: event.id, attention: attention
        )
    }

    /// The number of new tests in a summary block's `Tests:` line, such as 19 in "304/304, 19 new".
    static func testsAdded(from line: String?) -> Int {
        line?.firstMatch(of: /(\d+) new/).flatMap { Int($0.1) } ?? 0
    }

    private static func mergedEvent(task: String, goal: String?, commit: String, testsAdded: Int, at time: Date,
                                    again: Bool) -> NestEvent {
        let what = again ? "Swift merged \(task) again" : "Swift merged \(task)" + (goal.map { ": \($0)" } ?? "")
        return NestEvent(
            id: EventID.make(at: time), ts: time, sender: .bird(.swift), kind: .action, topic: .swiftTaskMerged,
            summary: what.count > NestEvent.summaryMaxLength ? String(what.prefix(NestEvent.summaryMaxLength - 1)) + "…" : what,
            data: ["task": .string(task), "commit": .string(commit), "tests_added": .number(Double(testsAdded))],
            undo: EventUndo(op: "git.revert", args: ["commit": .string(commit)]),
            causedBy: nil, attention: .none
        )
    }

    private func taskID(ofMerge commit: String) async throws -> String {
        let subject = try await git("log", "-1", "--format=%s", commit)
        return subject.firstMatch(of: /Merge branch 'task\/(.+)'/).map { String($0.1) } ?? commit
    }

    @discardableResult
    private func git(_ arguments: String...) async throws -> String {
        try await git(arguments: arguments)
    }

    @discardableResult
    private func git(arguments: [String]) async throws -> String {
        let output = try await shell.run(["git"] + arguments, in: repository)
        guard output.succeeded else { throw AutoMergeError.git(output.text) }
        return output.text.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
