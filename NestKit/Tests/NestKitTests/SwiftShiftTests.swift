import Foundation
import Testing
@testable import NestKit

struct SwiftShiftTests {
    /// The queue file on main: T9-01 is already merged, T9-02 waits on it.
    static let queueFile = """
    # Queue

    | id | goal | done_means | needs |
    | --- | --- | --- | --- |
    | T9-01 | The file T9-01.txt | T9-01.txt holds its id | Phase 1 |
    | T9-02 | The file T9-02.txt | T9-02.txt holds its id | T9-01 |
    """

    /// A repository whose main holds the rules, the queue file and T9-01's merge, plus a shift that builds it.
    func setUp(queueFile: String = Self.queueFile) async throws -> (TempRepo, TaskQueue, PresenceWatch, Published, SwiftShift) {
        let repo = try await TempRepo()
        try QueueRunnerTests.rules.write(to: repo.url.appending(path: "CLAUDE.md"), atomically: true, encoding: .utf8)
        try FileManager.default.createDirectory(at: repo.url.appending(path: "docs"), withIntermediateDirectories: true)
        try queueFile.write(to: repo.url.appending(path: "docs/queue.md"), atomically: true, encoding: .utf8)
        try await repo.git("add", ".")
        try await repo.git("commit", "-q", "-m", "Rules and queue")
        try await repo.git("switch", "-q", "-c", "task/T9-01")
        try "T9-01\n".write(to: repo.url.appending(path: "T9-01.txt"), atomically: true, encoding: .utf8)
        try await repo.git("add", "T9-01.txt")
        try await repo.git("commit", "-q", "-m", "T9-01: Add T9-01.txt")
        try await repo.git("switch", "-q", "main")
        try await repo.git("merge", "-q", "--no-ff", "task/T9-01", "-m", "Merge branch 'task/T9-01'")

        let queue = try TaskQueue(at: repo.url.appending(path: ".git/queue.sqlite"))
        let log = try UsageLog(at: repo.url.appending(path: ".git/usage.sqlite"))
        let presence = PresenceWatch()
        let published = Published()
        let runner = QueueRunner(
            queue: queue,
            runner: ManualRunner(repository: repo.url, session: try repo.script("session", QueueRunnerTests.session),
                                 tests: try repo.script("tests", "echo '1 test passed'")),
            merger: AutoMerge(repository: repo.url),
            mainTests: try repo.script("all", "echo 'all tests passed'"),
            publish: published.add,
            usageLog: log,
            budget: Budget(rules: BudgetRules(reserve: 0.25), log: log),
            presence: presence
        )
        return (repo, queue, presence, published, SwiftShift(runner: runner))
    }

    @Test func withYouAwayAndTheBudgetOpenANightBuildsTheReadyTaskMergesItAndReports() async throws {
        let (repo, queue, presence, published, shift) = try await setUp()
        defer { repo.remove() }
        await presence.receive(.presenceChanged(to: "away", was: "here"))

        let run = try await shift.tick()

        #expect(run?.outcomes.map(\.task.id) == ["T9-02"])
        #expect(try await queue.task("T9-01")?.state == .done)
        #expect(try await queue.task("T9-02")?.state == .done)
        #expect(try await repo.git("show", "main:T9-02.txt") == "T9-02")
        #expect(published.events.map(\.topic) == [.swiftTaskMerged, .swiftReportReady])
        let report = try #require(published.events.last)
        #expect(report.data["status"] == .string("green"))
        #expect(report.data["headline"] == .string("1 of 1 task merged."))
        #expect(report.data["tasks"] == .array([.string("ok")]))
    }

    @Test func withYouHereSwiftStartsNothing() async throws {
        let (repo, queue, presence, published, shift) = try await setUp()
        defer { repo.remove() }
        let main = try await repo.git("rev-parse", "main")
        await presence.receive(.presenceChanged(to: "here", was: "away"))

        #expect(try await shift.tick() == nil)

        #expect(try await queue.tasks().isEmpty)
        #expect(published.events.isEmpty)
        #expect(try await repo.git("rev-parse", "main") == main)
    }

    @Test func beforeSwiftHasHeardYouLeaveItStartsNothing() async throws {
        let (repo, queue, _, published, shift) = try await setUp()
        defer { repo.remove() }

        #expect(try await shift.tick() == nil)

        #expect(try await queue.tasks().isEmpty)
        #expect(published.events.isEmpty)
    }

    @Test func aNightWithNothingReadyPublishesNoReport() async throws {
        let (repo, queue, presence, published, shift) = try await setUp(queueFile: """
            | id | goal | done_means | needs |
            | --- | --- | --- | --- |
            | T9-01 | The file T9-01.txt | T9-01.txt holds its id | Phase 1 |
            """)
        defer { repo.remove() }
        await presence.receive(.presenceChanged(to: "away", was: "here"))

        let run = try await shift.tick()

        #expect(run?.outcomes.isEmpty == true)
        #expect(try await queue.task("T9-01")?.state == .done)
        #expect(published.events.isEmpty)
    }

    @Test func theQueueIsReadFromMainEvenWhenAHeldTaskLeftAnotherBranchCheckedOut() async throws {
        let (repo, queue, presence, _, shift) = try await setUp()
        defer { repo.remove() }
        try await repo.git("switch", "-q", "-c", "task/T9-99")
        try "| id | goal | done_means | needs |\n| T9-50 | Not on main | Never | |\n"
            .write(to: repo.url.appending(path: "docs/queue.md"), atomically: true, encoding: .utf8)
        try await repo.git("commit", "-q", "-am", "T9-99: Change the queue off main")
        await presence.receive(.presenceChanged(to: "away", was: "here"))

        _ = try await shift.tick()

        #expect(try await queue.tasks().map(\.id) == ["T9-01", "T9-02"])
    }
}
