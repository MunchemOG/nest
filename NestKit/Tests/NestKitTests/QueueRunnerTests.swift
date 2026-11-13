import Foundation
import Testing
@testable import NestKit

struct QueueRunnerTests {
    static let rules = "# Rules\n\nWork only inside this repository. Leave no TODO.\n"

    /// A stand-in for Claude Code that builds whichever task its prompt names: one commit, then the summary block.
    static let session = """
    id=$(printf '%s' "$1" | grep -o 'Do task [A-Z0-9-]*' | cut -d' ' -f3)
    printf '%s' "$1" > ".git/prompt-$id.txt"
    echo "$id" > "$id.txt"
    git add "$id.txt"
    git commit -q -m "$id: Add $id.txt"
    echo "Result: done"
    echo "Did: Added $id.txt."
    echo "Tests: 1/1, 1 new"
    echo "Files: $id.txt"
    echo "Noticed: nothing"
    echo "Next: none"
    """

    func setUp() async throws -> (TempRepo, TaskQueue, QueueRunner) {
        let repo = try await TempRepo()
        try Self.rules.write(to: repo.url.appending(path: "CLAUDE.md"), atomically: true, encoding: .utf8)
        try await repo.git("add", "CLAUDE.md")
        try await repo.git("commit", "-q", "-m", "Rules")
        let queue = try TaskQueue(at: repo.url.appending(path: ".git/queue.sqlite"))
        let runner = ManualRunner(
            repository: repo.url,
            session: try repo.script("session", Self.session),
            tests: try repo.script("tests", "echo '1 test passed'")
        )
        return (repo, queue, QueueRunner(queue: queue, runner: runner))
    }

    @Test func fiveTasksRunBackToBackEachOnAFreshBranchWithAllRulesFollowed() async throws {
        let (repo, queue, runner) = try await setUp()
        defer { repo.remove() }
        let ids = ["T9-01", "T9-02", "T9-03", "T9-04", "T9-05"]
        for id in ids {
            try await queue.add(QueuedTask(id: id, goal: "The file \(id).txt", doneMeans: "\(id).txt holds its id"))
        }

        let outcomes = try await runner.runUntilEmpty()

        #expect(outcomes.map(\.task.id) == ids)
        #expect(outcomes.allSatisfy { $0.isDone })
        #expect(outcomes.map { $0.summary?.did } == ids.map { "Added \($0).txt." })
        #expect(try await queue.tasks().map(\.state) == Array(repeating: .done, count: 5))
        for id in ids {
            // A fresh branch from main: exactly this task's commit, none of the others'.
            #expect(try await repo.git("log", "--format=%s", "main..task/\(id)") == "\(id): Add \(id).txt")
            let prompt = try String(contentsOf: repo.url.appending(path: ".git/prompt-\(id).txt"), encoding: .utf8)
            #expect(prompt.contains(Self.rules), "the session was not handed CLAUDE.md")
            #expect(prompt.contains("Do task \(id)"))
            #expect(prompt.contains("The file \(id).txt"))
            #expect(prompt.contains("\(id).txt holds its id"))
        }
        #expect(try await repo.git("log", "--format=%s", "main") == "Rules\nStart", "main was touched")
    }

    @Test func aHeldTaskIsMarkedHeldAndTheNextOneStillRuns() async throws {
        let (repo, queue, _) = try await setUp()
        defer { repo.remove() }
        let runner = QueueRunner(queue: queue, runner: ManualRunner(
            repository: repo.url,
            session: try repo.script("session", Self.session),
            tests: try repo.script("tests", "test -f T9-02.txt")
        ))
        try await queue.add(QueuedTask(id: "T9-01", goal: "One", doneMeans: "One"))
        try await queue.add(QueuedTask(id: "T9-02", goal: "Two", doneMeans: "Two"))

        let outcomes = try await runner.runUntilEmpty()

        #expect(outcomes.map(\.isDone) == [false, true])
        #expect(try await queue.task("T9-01")?.state == .held)
        #expect(try await queue.task("T9-02")?.state == .done)
    }

    @Test func aTaskWaitingOnAHeldNeedIsLeftQueued() async throws {
        let (repo, queue, _) = try await setUp()
        defer { repo.remove() }
        let runner = QueueRunner(queue: queue, runner: ManualRunner(
            repository: repo.url,
            session: try repo.script("session", Self.session),
            tests: try repo.script("tests", "exit 1")
        ))
        try await queue.add(QueuedTask(id: "T9-01", goal: "One", doneMeans: "One"))
        try await queue.add(QueuedTask(id: "T9-02", goal: "Two", doneMeans: "Two", needs: ["T9-01"]))

        let outcomes = try await runner.runUntilEmpty()

        #expect(outcomes.map(\.task.id) == ["T9-01"])
        #expect(try await queue.task("T9-02")?.state == .queued)
    }

    @Test func theRulesComeFromTheRepositorysOwnClaudeFile() async throws {
        let (repo, _, _) = try await setUp()
        defer { repo.remove() }
        let runner = ManualRunner(repository: repo.url, session: ["true"], tests: ["true"])
        #expect(try runner.rules() == Self.rules)
        #expect(ManualRunner.prompt(for: ManualRunnerTests.task, rules: Self.rules).hasPrefix(Self.rules))
    }

    @Test func aRepositoryWithoutRulesIsRefusedBeforeAnythingHappens() async throws {
        let repo = try await TempRepo()
        defer { repo.remove() }
        try await repo.git("rm", "-q", "CLAUDE.md")
        try await repo.git("commit", "-q", "-m", "No rules")
        let runner = ManualRunner(repository: repo.url, session: try repo.script("session", Self.session), tests: ["true"])
        await #expect(throws: ManualRunnerError.noRules) { try await runner.run(ManualRunnerTests.task) }
        #expect(try await repo.git("branch", "--show-current") == "main")
    }
}
