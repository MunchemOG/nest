import Foundation
import Testing
@testable import NestKit

struct RunSettingsTests {
    /// A stand-in for Claude Code that writes every argument it was given, each ended by a NUL, then does the task.
    static let recordingSession = """
    printf '%s\\0' "$@" > .git/arguments.txt
    echo hello > greeting.txt
    git add greeting.txt
    git commit -q -m "T9-01: Add the greeting"
    echo "Result: done"
    echo "Did: Added the greeting file."
    echo "Tests: 1/1, 1 new"
    """

    @Test func opusMaxSoloBecomesTheClaudeCodeArguments() {
        let settings = RunSettings(model: .opus, effort: .max, subagents: false)
        #expect(settings.arguments == ["--model", "opus", "--effort", "max", "--disallowed-tools", "Agent"])
    }

    @Test func withSubagentsNothingIsDisallowed() {
        let settings = RunSettings(model: .sonnet, effort: .high, subagents: true)
        #expect(settings.arguments == ["--model", "sonnet", "--effort", "high"])
    }

    @Test func settingsSurviveTheirShortForm() {
        let settings = RunSettings(model: .fable, effort: .xhigh, subagents: true)
        #expect(settings.code == "fable/xhigh/agents")
        #expect(RunSettings(code: "opus/max/solo") == RunSettings(model: .opus, effort: .max, subagents: false))
        #expect(RunSettings(code: settings.code) == settings)
        #expect(RunSettings(code: "gpt/max/solo") == nil)
        #expect(RunSettings(code: "") == nil)
    }

    @Test func theSessionIsToldWhetherItMaySplitWork() {
        #expect(RunSettings(model: .opus, effort: .max, subagents: true).promptLine.contains("subagents"))
        #expect(RunSettings(model: .opus, effort: .max, subagents: false).promptLine.contains("one session"))
    }

    @Test func theQueueKeepsATasksOverride() async throws {
        let folder = FileManager.default.temporaryDirectory.appending(path: "RunSettingsTests-\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: folder) }
        let queue = try TaskQueue(at: folder.appending(path: "queue.sqlite"))
        let opus = RunSettings(model: .opus, effort: .max, subagents: false)

        try await queue.add(QueuedTask(id: "Y-01", goal: "A", doneMeans: "a", run: opus))
        try await queue.add(QueuedTask(id: "Y-02", goal: "B", doneMeans: "b"))
        try await queue.setRun(RunSettings(model: .haiku, effort: .low, subagents: false), for: "Y-02")

        #expect(try await queue.task("Y-01")?.run == opus)
        #expect(try await queue.task("Y-02")?.run == RunSettings(model: .haiku, effort: .low, subagents: false))
        #expect(try await queue.claim()?.run == opus)
    }

    @Test func aQueueFromBeforeOverridesOpensAndKeepsItsTasks() async throws {
        let folder = FileManager.default.temporaryDirectory.appending(path: "RunSettingsTests-\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: folder) }
        let url = folder.appending(path: "queue.sqlite")
        do {
            let old = try SQLiteDatabase(at: url)
            try old.execute("""
                CREATE TABLE tasks (id TEXT PRIMARY KEY, goal TEXT NOT NULL, done_means TEXT NOT NULL, priority INTEGER NOT NULL,
                needs TEXT NOT NULL, source TEXT NOT NULL, state TEXT NOT NULL)
                """)
            try old.execute("INSERT INTO tasks VALUES ('S2-01', 'Old', 'old', 0, '', 'you', 'done')")
        }

        let queue = try TaskQueue(at: url)
        try await queue.add(QueuedTask(id: "Y-01", goal: "New", doneMeans: "new", run: RunSettings(model: .opus, effort: .max, subagents: true)))

        #expect(try await queue.task("S2-01")?.run == nil)
        #expect(try await queue.task("Y-01")?.run?.model == .opus)
    }

    @Test func aTaskWithAnOverrideStartsItsSessionWithIt() async throws {
        let repo = try await TempRepo()
        defer { repo.remove() }
        let runner = ManualRunner(
            repository: repo.url,
            session: try repo.script("session", Self.recordingSession),
            tests: try repo.script("tests", ManualRunnerTests.passingTests),
            defaults: RunSettings(model: .sonnet, effort: .high, subagents: true)
        )
        var task = ManualRunnerTests.task
        task.run = RunSettings(model: .opus, effort: .max, subagents: false)

        _ = try await runner.run(task)

        let arguments = try String(contentsOf: repo.url.appending(path: ".git/arguments.txt"), encoding: .utf8)
            .split(separator: "\0").map(String.init)
        #expect(Array(arguments.prefix(6)) == ["--model", "opus", "--effort", "max", "--disallowed-tools", "Agent"])
        #expect(arguments.count == 7)
        #expect(arguments.last?.contains("Do task T9-01") == true)
        #expect(arguments.last?.contains("one session") == true)
    }

    @Test func aTaskWithNoOverrideUsesTheDefault() async throws {
        let repo = try await TempRepo()
        defer { repo.remove() }
        let runner = ManualRunner(
            repository: repo.url,
            session: try repo.script("session", Self.recordingSession),
            tests: try repo.script("tests", ManualRunnerTests.passingTests),
            defaults: RunSettings(model: .sonnet, effort: .high, subagents: true)
        )

        _ = try await runner.run(ManualRunnerTests.task)

        let arguments = try String(contentsOf: repo.url.appending(path: ".git/arguments.txt"), encoding: .utf8)
            .split(separator: "\0").map(String.init)
        #expect(Array(arguments.prefix(4)) == ["--model", "sonnet", "--effort", "high"])
        #expect(arguments.count == 5)
    }

    @Test func theQueuedOverrideReachesTheRunner() {
        let opus = RunSettings(model: .opus, effort: .max, subagents: false)
        let task = QueueTask(QueuedTask(id: "Y-01", goal: "A", doneMeans: "a", run: opus))
        #expect(task.run == opus)
    }
}
