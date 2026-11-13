import Foundation
import Testing
@testable import NestKit

struct ManualRunnerTests {
    static let task = QueueTask(
        id: "T9-01",
        goal: "A greeting file",
        doneMeans: "greeting.txt says hello",
        needs: "nothing"
    )

    /// A stand-in for Claude Code that does the task: one commit, then the summary block.
    static let goodSession = """
    echo "$1" > .git/prompt.txt
    echo hello > greeting.txt
    git add greeting.txt
    git commit -q -m "T9-01: Add the greeting"
    echo "Working on it."
    echo "Result: done"
    echo "Did: Added the greeting file."
    echo "Tests: 1/1, 1 new"
    echo "Files: greeting.txt"
    echo "Noticed: nothing"
    echo "Next: T9-02, needs met"
    """

    static let passingTests = "grep -q hello greeting.txt && echo '1 test passed'"

    @Test func oneTaskEndsOnItsOwnBranchWithPassingTestsAndTheSummaryBlock() async throws {
        let repo = try await TempRepo()
        defer { repo.remove() }
        let runner = ManualRunner(
            repository: repo.url,
            session: try repo.script("session", Self.goodSession),
            tests: try repo.script("tests", Self.passingTests)
        )

        let outcome = try await runner.run(Self.task)

        #expect(outcome.isDone)
        #expect(outcome.held == nil)
        #expect(outcome.branch == "task/T9-01")
        #expect(outcome.testsPassed)
        #expect(outcome.summary?.result == .done)
        #expect(outcome.summary?.did == "Added the greeting file.")
        #expect(outcome.summary?.files == "greeting.txt")
        #expect(try await repo.git("branch", "--show-current") == "task/T9-01")
        #expect(try await repo.git("log", "--format=%s", "main..task/T9-01") == "T9-01: Add the greeting")
        #expect(try await repo.git("log", "--format=%s", "main") == "Start")
    }

    @Test func theSessionIsHandedTheTaskAndToldNotToMerge() async throws {
        let repo = try await TempRepo()
        defer { repo.remove() }
        let runner = ManualRunner(
            repository: repo.url,
            session: try repo.script("session", Self.goodSession),
            tests: try repo.script("tests", Self.passingTests)
        )

        _ = try await runner.run(Self.task)

        let prompt = try String(contentsOf: repo.url.appending(path: ".git/prompt.txt"), encoding: .utf8)
        #expect(prompt.contains("Do task T9-01"))
        #expect(prompt.contains("A greeting file"))
        #expect(prompt.contains("greeting.txt says hello"))
        #expect(prompt.contains("CLAUDE.md"))
        #expect(prompt.contains("Do not merge"))
    }

    @Test func youWatchEachStepAndEveryLineAsItHappens() async throws {
        let repo = try await TempRepo()
        defer { repo.remove() }
        let watched = Watched()
        let runner = ManualRunner(
            repository: repo.url,
            session: try repo.script("session", Self.goodSession),
            tests: try repo.script("tests", Self.passingTests),
            watch: { watched.add($0) }
        )

        _ = try await runner.run(Self.task)

        let lines = watched.lines
        let branch = try #require(lines.firstIndex { $0.contains("task/T9-01") })
        let working = try #require(lines.firstIndex(of: "Working on it."))
        let tests = try #require(lines.firstIndex(of: "1 test passed"))
        #expect(branch < working)
        #expect(working < tests)
        #expect(lines.last?.contains("done") == true)
    }

    @Test func failingTestsHoldTheTaskOnItsBranch() async throws {
        let repo = try await TempRepo()
        defer { repo.remove() }
        let runner = ManualRunner(
            repository: repo.url,
            session: try repo.script("session", Self.goodSession),
            tests: try repo.script("tests", "echo '1 test failed'; exit 1")
        )

        let outcome = try await runner.run(Self.task)

        #expect(!outcome.isDone)
        #expect(!outcome.testsPassed)
        #expect(outcome.held?.contains("suite") == true)
        #expect(outcome.summary?.result == .done)
        #expect(try await repo.git("branch", "--show-current") == "task/T9-01")
        #expect(try await repo.git("log", "--format=%s", "main") == "Start")
    }

    @Test func aSessionWithNoSummaryBlockIsHeld() async throws {
        let repo = try await TempRepo()
        defer { repo.remove() }
        let session = """
        echo hello > greeting.txt
        git add greeting.txt
        git commit -q -m "T9-01: Add the greeting"
        echo "All finished!"
        """
        let runner = ManualRunner(
            repository: repo.url,
            session: try repo.script("session", session),
            tests: try repo.script("tests", Self.passingTests)
        )

        let outcome = try await runner.run(Self.task)

        #expect(!outcome.isDone)
        #expect(outcome.summary == nil)
        #expect(outcome.held?.contains("summary block") == true)
    }

    @Test func aSessionThatSaysHeldIsHeldWithoutRunningTheSuite() async throws {
        let repo = try await TempRepo()
        defer { repo.remove() }
        let session = """
        echo "Result: held"
        echo "Did: Nothing."
        echo "If held: The goal needs a token that does not exist; fairly sure."
        """
        let runner = ManualRunner(
            repository: repo.url,
            session: try repo.script("session", session),
            tests: try repo.script("tests", "touch .git/tests-ran")
        )

        let outcome = try await runner.run(Self.task)

        #expect(!outcome.isDone)
        #expect(outcome.summary?.result == .held)
        #expect(outcome.held?.contains("token that does not exist") == true)
        #expect(!FileManager.default.fileExists(atPath: repo.url.appending(path: ".git/tests-ran").path))
    }

    @Test func aSessionThatCommitsNothingIsHeld() async throws {
        let repo = try await TempRepo()
        defer { repo.remove() }
        let runner = ManualRunner(
            repository: repo.url,
            session: try repo.script("session", "echo 'Result: done'; echo 'Did: Everything.'"),
            tests: try repo.script("tests", "true")
        )

        let outcome = try await runner.run(Self.task)

        #expect(!outcome.isDone)
        #expect(outcome.held?.contains("no commits") == true)
    }

    @Test func aSessionThatLeavesTheBranchIsHeld() async throws {
        let repo = try await TempRepo()
        defer { repo.remove() }
        let session = """
        git switch -q main
        echo hello > greeting.txt
        git add greeting.txt
        git commit -q -m "T9-01: Add the greeting"
        echo "Result: done"
        """
        let runner = ManualRunner(
            repository: repo.url,
            session: try repo.script("session", session),
            tests: try repo.script("tests", "true")
        )

        let outcome = try await runner.run(Self.task)

        #expect(!outcome.isDone)
        #expect(outcome.held?.contains("left task/T9-01") == true)
    }

    @Test func uncommittedChangesStopTheRunBeforeAnythingHappens() async throws {
        let repo = try await TempRepo()
        defer { repo.remove() }
        try "Half-written.\n".write(to: repo.url.appending(path: "README.md"), atomically: true, encoding: .utf8)
        let runner = ManualRunner(
            repository: repo.url,
            session: try repo.script("session", "touch .git/session-ran"),
            tests: try repo.script("tests", "true")
        )

        await #expect(throws: ManualRunnerError.uncommittedChanges) {
            try await runner.run(Self.task)
        }
        #expect(try await repo.git("branch", "--show-current") == "main")
        #expect(!FileManager.default.fileExists(atPath: repo.url.appending(path: ".git/session-ran").path))
        let readme = try String(contentsOf: repo.url.appending(path: "README.md"), encoding: .utf8)
        #expect(readme == "Half-written.\n")
    }

    @Test func anExistingTaskBranchIsContinuedNotRemade() async throws {
        let repo = try await TempRepo()
        defer { repo.remove() }
        try await repo.git("switch", "-q", "-c", "task/T9-01")
        try "Earlier.\n".write(to: repo.url.appending(path: "earlier.txt"), atomically: true, encoding: .utf8)
        try await repo.git("add", ".")
        try await repo.git("commit", "-q", "-m", "T9-01: Earlier work")
        try await repo.git("switch", "-q", "main")
        let runner = ManualRunner(
            repository: repo.url,
            session: try repo.script("session", Self.goodSession),
            tests: try repo.script("tests", Self.passingTests)
        )

        let outcome = try await runner.run(Self.task)

        #expect(outcome.isDone)
        let subjects = try await repo.git("log", "--format=%s", "main..task/T9-01")
        #expect(subjects == "T9-01: Add the greeting\nT9-01: Earlier work")
    }
}

/// Collects the lines a runner shows while it works.
final class Watched: @unchecked Sendable {
    private let lock = NSLock()
    private var stored: [String] = []

    var lines: [String] { lock.withLock { stored } }

    func add(_ line: String) {
        lock.withLock { stored.append(line) }
    }
}
