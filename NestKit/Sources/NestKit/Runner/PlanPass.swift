import Foundation

/// Turns a rough idea, such as one of Crow's pitches, into small tested tasks by asking Claude Code in plan mode.
public struct PlanPass: Sendable {
    /// The repository the tasks are for; the session runs inside it.
    public let repository: URL
    /// The command that starts a non-interactive session; plan mode and the prompt are added after it.
    public let session: [String]

    private let shell = Shell()

    /// A plan pass over `repository` that starts sessions with `session`.
    public init(repository: URL, session: [String]) {
        self.repository = repository
        self.session = session
    }

    /// What plan mode is asked for (see `docs/house-rules.md`).
    public static func prompt(for idea: String) -> String {
        """
        Plan this rough idea for the Nest; do not build anything: \(idea)

        Work out the smallest version that would satisfy it, what it would touch, and anything it needs that the Nest \
        does not have yet. Then reply with its tasks as table rows, in build order, each small enough for one session \
        and each with its own "done means" test:

        | id | goal | done_means | needs |
        | --- | --- | --- | --- |
        | P-01 | <what it builds> | <the test that proves it> | - |

        If it needs anything outside the Nest's own code, reply with one line instead: Dropped: <why>.
        """
    }

    /// Asks plan mode about `idea` and reads its answer into tasks with ids `<prefix>-01`, `<prefix>-02`, ….
    public func plan(_ idea: String, as prefix: String) async throws -> Plan {
        let said = try await shell.run(session + ["--permission-mode", "plan", Self.prompt(for: idea)], in: repository)
        guard said.succeeded else { throw PlanPassError.sessionFailed(said.text) }
        return try Self.plan(from: said.text, as: prefix)
    }

    /// The plan in a plan-mode answer: its task rows, each needing the one before, or its `Dropped:` line.
    static func plan(from answer: String, as prefix: String) throws -> Plan {
        let rows = QueueFile(text: answer).tasks
        if rows.isEmpty {
            let dropped = answer.split(separator: "\n").lazy
                .map { $0.trimmingCharacters(in: .whitespaces) }
                .first { $0.hasPrefix("Dropped:") }
            guard let dropped else { throw PlanPassError.noPlan }
            return Plan(tasks: [], dropped: dropped.dropFirst("Dropped:".count).trimmingCharacters(in: .whitespaces))
        }
        if let untested = rows.first(where: { $0.doneMeans.isEmpty }) {
            throw PlanPassError.taskWithoutTest(untested.id)
        }
        let ids = rows.indices.map { "\(prefix)-" + String(format: "%02d", $0 + 1) }
        return Plan(tasks: rows.enumerated().map { index, row in
            QueuedTask(id: ids[index], goal: row.goal, doneMeans: row.doneMeans,
                       needs: index == 0 ? [] : [ids[index - 1]], source: .crow)
        })
    }

    /// Queues `plan`'s tasks in order, behind every task you queued yourself.
    public func queue(_ plan: Plan, into queue: TaskQueue) async throws {
        let yours = try await queue.tasks().filter { $0.source == .you }.map(\.priority)
        let priority = min(yours.min() ?? 0, 0) - 1
        for task in plan.tasks {
            try await queue.add(QueuedTask(id: task.id, goal: task.goal, doneMeans: task.doneMeans, priority: priority,
                                           needs: task.needs, source: task.source))
        }
    }
}
