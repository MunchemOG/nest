import Foundation

/// Runs scheduled jobs with no one at the Mac: Claude Code in a fresh git worktree on the job's own branch,
/// so your checkout is never touched. Anything Claude Code would ask about is refused. Deleting the branch undoes it.
public struct JobRunner: Sendable {
    /// Swift's folder; worktrees live in `worktrees/` inside it while a job runs.
    public let folder: URL
    /// The command that starts Claude Code.
    public let command: [String]

    private let shell = Shell()

    /// A runner that keeps worktrees in `folder` and starts Claude Code with `command`.
    public init(folder: URL, command: [String] = ClaudeSession.claude) {
        self.folder = folder
        self.command = command
    }

    /// The first job due at `now`, or nil if none is or you're here.
    public static func next(_ jobs: [SwiftJob], at now: Date, away: Bool, pattern: WorkPattern,
                            calendar: Calendar = .current) -> SwiftJob? {
        guard away else { return nil }
        return jobs.first { $0.isDue(at: now, pattern: pattern, calendar: calendar) }
    }

    /// Runs `job` in the repository at `repository` and returns where its work is.
    public func run(_ job: SwiftJob, in repository: URL, at time: Date = .now) async throws -> JobResult {
        let worktree = folder.appending(path: "worktrees/\(job.id)-\(Int(time.timeIntervalSince1970))")
        try FileManager.default.createDirectory(at: worktree.deletingLastPathComponent(), withIntermediateDirectories: true)
        let branch = try await freeBranch(job.branch, in: repository)
        try await git(["worktree", "add", "-q", "-b", branch, worktree.path, "HEAD"], in: repository)
        defer { Task { [shell] in _ = try? await shell.run(["git", "worktree", "remove", "--force", worktree.path], in: repository) } }

        let session = ClaudeSession(ClaudeSession.Options(folder: worktree, model: job.settings.model, effort: job.settings.effort,
                                                          mode: job.mode, command: command))
        var summary = ""
        var cost = 0.0
        try await session.start()
        try await session.send(ClaudeSession.message(job.prompt, ultracode: job.ultracode))
        for await event in session.events {
            switch event {
            case .text(_, let text): summary = text
            case .permission(let request): try await session.answer(request, with: .deny)
            case .finished(let finish): cost = finish.costUSD
            default: break
            }
            if case .finished = event { break }
        }
        await session.stop()

        if try await !git(["status", "--porcelain"], in: worktree).isEmpty {
            try await git(["add", "-A"], in: worktree)
            try await git(["commit", "-q", "-m", "Swift: \(job.title)"], in: worktree)
        }
        try await git(["worktree", "remove", "--force", worktree.path], in: repository)
        let event = NestEvent(
            id: EventID.make(at: time), ts: time, sender: .bird(.swift), kind: .signal, topic: .swiftRunFinished,
            summary: String("Swift ran \"\(job.title)\" on \(branch)".prefix(NestEvent.summaryMaxLength)),
            data: ["tasks": .array([.string(job.id)]), "branch": .string(branch), "repository": .string(repository.path)],
            undo: EventUndo(op: "git.branch.delete", args: ["branch": .string(branch), "repository": .string(repository.path)]),
            causedBy: nil, attention: .inbox
        )
        return JobResult(branch: branch, summary: summary, costUSD: cost, event: event)
    }

    /// Performs a job run's undo: deletes the branch its work landed on.
    public static func undo(_ event: NestEvent, in repository: URL) async throws {
        guard let undo = event.undo, undo.op == "git.branch.delete", let branch = undo.args["branch"]?.string else {
            throw AutoMergeError.cannotUndo(event.id)
        }
        let output = try await Shell().run(["git", "branch", "-D", branch], in: repository)
        guard output.succeeded else { throw AutoMergeError.git(output.text) }
    }

    private func freeBranch(_ name: String, in repository: URL) async throws -> String {
        var candidate = name
        var number = 2
        while try await shell.run(["git", "rev-parse", "-q", "--verify", "refs/heads/\(candidate)"], in: repository).succeeded {
            candidate = "\(name)-\(number)"
            number += 1
        }
        return candidate
    }

    @discardableResult
    private func git(_ arguments: [String], in folder: URL) async throws -> String {
        let output = try await shell.run(["git"] + arguments, in: folder)
        guard output.succeeded else { throw AutoMergeError.git(output.text) }
        return output.text.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
