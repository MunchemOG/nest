import Foundation

/// Turns one task into a tested branch: a fresh branch, one Claude Code session, the summary block, then the suite.
public struct ManualRunner: Sendable {
    /// The repository the task is built in.
    public let repository: URL
    /// The command that starts a non-interactive session; the prompt is added as its last argument.
    public let session: [String]
    /// The command that runs the test suite.
    public let tests: [String]
    /// The branch task branches are made from.
    public let base: String
    /// Called with each step and each line the session and the suite print, as they happen.
    public let watch: @Sendable (String) -> Void

    private let shell = Shell()

    /// A runner for `repository` that starts sessions with `session` and checks them with `tests`.
    public init(
        repository: URL,
        session: [String],
        tests: [String],
        base: String = "main",
        watch: @escaping @Sendable (String) -> Void = { _ in }
    ) {
        self.repository = repository
        self.session = session
        self.tests = tests
        self.base = base
        self.watch = watch
    }

    /// What the session is told: the repository's rules, then the task and to leave merging alone.
    public static func prompt(for task: QueueTask, rules: String) -> String {
        """
        \(rules)

        Do task \(task.id). Goal: \(task.goal). Done means: \(task.doneMeans). \
        Follow the rules above (CLAUDE.md) and their task flow on branch \(task.branch). \
        Do not merge: commit on \(task.branch) and stop. \
        Do not ask questions; if you are blocked, say so with Result: held or unclear. \
        End with the summary block.
        """
    }

    /// The rules every session follows: the repository's `CLAUDE.md`.
    public func rules() throws -> String {
        guard let rules = try? String(contentsOf: repository.appending(path: "CLAUDE.md"), encoding: .utf8) else {
            throw ManualRunnerError.noRules
        }
        return rules
    }

    /// Runs `task` and reports whether it ended done or held; the work stays on the task's branch either way.
    public func run(_ task: QueueTask) async throws -> RunOutcome {
        guard try await git("status", "--porcelain", "--untracked-files=no").isEmpty else {
            throw ManualRunnerError.uncommittedChanges
        }
        let rules = try rules()
        try await switchToBranch(of: task)

        watch("\(task.id): session started")
        let said = try await shell.run(session + [Self.prompt(for: task, rules: rules)], in: repository, watch: watch)
        let summary = SummaryBlock(in: said.text)

        if let held = try await reasonToHold(task, summary: summary, status: said.status) {
            return finish(task, summary: summary, testsPassed: false, held: held)
        }

        watch("\(task.id): running the suite")
        let suite = try await shell.run(tests, in: repository, watch: watch)
        let held = suite.succeeded ? nil : "the suite failed when the runner ran it"
        return finish(task, summary: summary, testsPassed: suite.succeeded, held: held)
    }

    private func switchToBranch(of task: QueueTask) async throws {
        let exists = try await shell.run(["git", "rev-parse", "-q", "--verify", "refs/heads/\(task.branch)"], in: repository)
        if exists.succeeded {
            try await git("switch", "-q", task.branch)
            watch("\(task.id): continuing on \(task.branch)")
        } else {
            try await git("switch", "-q", "-c", task.branch, base)
            watch("\(task.id): new branch \(task.branch) from \(base)")
        }
    }

    private func reasonToHold(_ task: QueueTask, summary: SummaryBlock?, status: Int32) async throws -> String? {
        let branch = try await git("branch", "--show-current")
        guard branch == task.branch else {
            return "the session left \(task.branch) and ended on \(branch.isEmpty ? "no branch" : branch)"
        }
        guard let summary else {
            return "the session ended without the summary block (exit status \(status))"
        }
        guard summary.result == .done else {
            return "the session said \(summary.result.rawValue): \(summary.ifHeld ?? "no reason given")"
        }
        guard try await git("rev-list", "--count", "\(base)..\(task.branch)") != "0" else {
            return "the session said done but \(task.branch) has no commits beyond \(base)"
        }
        return nil
    }

    private func finish(_ task: QueueTask, summary: SummaryBlock?, testsPassed: Bool, held: String?) -> RunOutcome {
        if let held {
            watch("\(task.id): held on \(task.branch): \(held)")
        } else {
            watch("\(task.id): done on \(task.branch), suite green")
        }
        return RunOutcome(task: task, branch: task.branch, summary: summary, testsPassed: testsPassed, held: held)
    }

    @discardableResult
    private func git(_ arguments: String...) async throws -> String {
        let output = try await shell.run(["git"] + arguments, in: repository)
        guard output.succeeded else { throw ManualRunnerError.git(output.text) }
        return output.text.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
