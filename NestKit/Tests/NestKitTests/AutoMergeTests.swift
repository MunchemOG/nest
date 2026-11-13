import Foundation
import Testing
@testable import NestKit

struct AutoMergeTests {
    static let now = Date(timeIntervalSince1970: 1_794_600_000)

    /// Builds T9-01 on its branch with the manual runner, as a real run would, and returns how it ended.
    func greenRun(in repo: TempRepo) async throws -> RunOutcome {
        let runner = ManualRunner(
            repository: repo.url,
            session: try repo.script("session", ManualRunnerTests.goodSession),
            tests: try repo.script("tests", ManualRunnerTests.passingTests)
        )
        return try await runner.run(ManualRunnerTests.task)
    }

    @Test func aGreenTaskMergesWithNoHelpAndOneTapReturnsToTheRestorePoint() async throws {
        let repo = try await TempRepo()
        defer { repo.remove() }
        let before = try await repo.git("rev-parse", "main")
        let outcome = try await greenRun(in: repo)
        let merger = AutoMerge(repository: repo.url)

        let merged = try await merger.merge(outcome, at: Self.now)

        #expect(try await repo.git("branch", "--show-current") == "main")
        #expect(try await repo.git("log", "-1", "--format=%s", "main") == "Merge branch 'task/T9-01'")
        #expect(try await repo.git("show", "main:greeting.txt") == "hello")
        #expect(try await repo.git("rev-parse", "nest/restore/T9-01") == before, "no restore point before the merge")
        #expect(merged.topic == .swiftTaskMerged)
        #expect(merged.kind == .action)
        #expect(merged.sender == .bird(.swift))
        #expect(merged.summary == "Swift merged T9-01: A greeting file")
        #expect(merged.data["task"] == .string("T9-01"))
        #expect(merged.data["commit"] == .string(try await repo.git("rev-parse", "main")))
        #expect(merged.data["tests_added"] == .number(1))
        #expect(merged.undo?.op == "git.revert")
        #expect(merged.undo?.args["commit"] == merged.data["commit"])

        let undone = try await merger.undo(merged, at: Self.now)

        #expect(try await repo.git("diff", "nest/restore/T9-01", "main") == "", "main is not back at the restore point")
        #expect(try await repo.git("log", "--format=%s", "-3", "main").contains("Merge branch 'task/T9-01'"), "history was rewritten")
        #expect(undone.kind == .undo)
        #expect(undone.data["target"] == .string(merged.id))
        #expect(undone.undo?.op == "git.revert", "the undo has no redo")
        #expect(undone.summary == "Swift undid the merge of T9-01")
    }

    @Test func redoPutsTheMergeBack() async throws {
        let repo = try await TempRepo()
        defer { repo.remove() }
        let merger = AutoMerge(repository: repo.url)
        let merged = try await merger.merge(try await greenRun(in: repo), at: Self.now)
        let undone = try await merger.undo(merged, at: Self.now)

        _ = try await merger.undo(undone, at: Self.now)

        #expect(try await repo.git("show", "main:greeting.txt") == "hello")
    }

    @Test func aHeldTaskIsNeverMerged() async throws {
        let repo = try await TempRepo()
        defer { repo.remove() }
        let held = RunOutcome(task: ManualRunnerTests.task, branch: "task/T9-01", summary: nil, testsPassed: false, held: "red")
        await #expect(throws: AutoMergeError.notGreen("T9-01")) {
            try await AutoMerge(repository: repo.url).merge(held, at: Self.now)
        }
        #expect(try await repo.git("tag", "--list") == "")
    }

    @Test func aMergeThatConflictsIsAbortedAndLeavesMainAsItWas() async throws {
        let repo = try await TempRepo()
        defer { repo.remove() }
        let outcome = try await greenRun(in: repo)
        try await repo.git("switch", "-q", "main")
        try "goodbye\n".write(to: repo.url.appending(path: "greeting.txt"), atomically: true, encoding: .utf8)
        try await repo.git("add", "greeting.txt")
        try await repo.git("commit", "-q", "-m", "Meanwhile on main")
        let before = try await repo.git("rev-parse", "main")

        await #expect(throws: AutoMergeError.conflict("T9-01")) {
            try await AutoMerge(repository: repo.url).merge(outcome, at: Self.now)
        }
        #expect(try await repo.git("rev-parse", "main") == before)
        #expect(try await repo.git("status", "--porcelain", "--untracked-files=no") == "")
    }

    @Test func testsAddedAreReadFromTheSummaryBlock() {
        #expect(AutoMerge.testsAdded(from: "304/304, 19 new") == 19)
        #expect(AutoMerge.testsAdded(from: "12/12") == 0)
        #expect(AutoMerge.testsAdded(from: nil) == 0)
    }
}
