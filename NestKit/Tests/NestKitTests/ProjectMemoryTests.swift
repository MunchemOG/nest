import Foundation
import Testing
@testable import NestKit

struct ProjectMemoryTests {
    static let index = "# Memory\n\nBuilt by Opus at max effort.\n"
    static let runner = "---\ncovers: [Sources/Runner, docs/queue.md]\n---\n# Runner\n\nThe runner turns tasks into branches.\n"
    static let tokens = "---\ncovers: [Sources/Tokens]\n---\n# Tokens\n\nEvery value comes from tokens.json.\n"
    static let budget = "---\ncovers: [Sources/Budget]\n---\n# Budget\n\nCaps and the forecast.\n"

    /// A repository with code under `Sources/` and a three-section brief that matches it.
    func repoWithBrief() async throws -> TempRepo {
        let repo = try await TempRepo()
        try write(repo, "Sources/Runner/Runner.swift", "struct Runner {}\n")
        try write(repo, "Sources/Tokens/Tokens.swift", "enum Tokens {}\n")
        try write(repo, "Sources/Budget/Budget.swift", "struct Budget {}\n")
        try await repo.git("add", ".")
        try await repo.git("commit", "-q", "-m", "Code")
        try write(repo, ".nest/memory/README.md", Self.index)
        try write(repo, ".nest/memory/runner.md", Self.runner)
        try write(repo, ".nest/memory/tokens.md", Self.tokens)
        try write(repo, ".nest/memory/budget.md", Self.budget)
        try await repo.git("add", ".")
        try await repo.git("commit", "-q", "-m", "Memory")
        return repo
    }

    func write(_ repo: TempRepo, _ path: String, _ text: String) throws {
        let url = repo.url.appending(path: path)
        try FileManager.default.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
        try text.write(to: url, atomically: true, encoding: .utf8)
    }

    func commit(_ repo: TempRepo, _ path: String, _ text: String) async throws {
        try write(repo, path, text)
        try await repo.git("add", path)
        try await repo.git("commit", "-q", "-m", "Change \(path)")
    }

    @Test func theBriefIsReadWithWhatEachSectionCovers() async throws {
        let repo = try await repoWithBrief()
        defer { repo.remove() }

        let brief = try #require(try await ProjectMemory.read(in: repo.url, at: "main"))

        #expect(brief.index == Self.index)
        #expect(brief.sections.map(\.name) == ["budget", "runner", "tokens"])
        #expect(brief.sections.first { $0.name == "runner" }?.covers == ["Sources/Runner", "docs/queue.md"])
        #expect(brief.sections.first { $0.name == "tokens" }?.body.contains("tokens.json") == true)
    }

    @Test func aRepositoryWithoutABriefHasNone() async throws {
        let repo = try await TempRepo()
        defer { repo.remove() }
        #expect(try await ProjectMemory.read(in: repo.url, at: "main") == nil)
    }

    @Test func everyTasksPromptCarriesTheBriefAndHowToKeepItTrue() async throws {
        let repo = try await repoWithBrief()
        defer { repo.remove() }
        let runner = ManualRunner(repository: repo.url, session: try repo.script("session", ManualRunnerTests.goodSession),
                                  tests: try repo.script("tests", ManualRunnerTests.passingTests))

        _ = try await runner.run(ManualRunnerTests.task)

        let prompt = try String(contentsOf: repo.url.appending(path: ".git/prompt.txt"), encoding: .utf8)
        #expect(prompt.contains("The runner turns tasks into branches."))
        #expect(prompt.contains("Every value comes from tokens.json."))
        #expect(prompt.contains(ProjectMemory.keepingItTrue))
    }

    @Test func changingACoveredFileMarksItsSectionStaleUntilTheSectionIsUpdated() async throws {
        let repo = try await repoWithBrief()
        defer { repo.remove() }
        #expect(try await ProjectMemory.stale(in: repo.url, at: "main").isEmpty)

        try await commit(repo, "Sources/Runner/Runner.swift", "struct Runner { let queue: [String] }\n")
        #expect(try await ProjectMemory.stale(in: repo.url, at: "main") == ["runner"])

        try await commit(repo, ".nest/memory/runner.md", Self.runner + "\nIt keeps a queue.\n")
        #expect(try await ProjectMemory.stale(in: repo.url, at: "main").isEmpty)
    }

    @Test func pastHalfStaleARebuildIsQueuedOnce() async throws {
        let repo = try await repoWithBrief()
        let support = FileManager.default.temporaryDirectory.appending(path: "ProjectMemoryTests-\(UUID().uuidString)")
        defer { repo.remove(); try? FileManager.default.removeItem(at: support) }
        try FileManager.default.createDirectory(at: support, withIntermediateDirectories: true)
        let queue = try TaskQueue(at: support.appending(path: "queue.sqlite"))
        try await queue.add(QueuedTask(id: "Y-01", goal: "Something", doneMeans: "It works", priority: 3))
        var project = try await SwiftProject.picked(repo.url, taken: [])
        project.memory = RunSettings(model: .fable, effort: .max, subagents: true)

        try await commit(repo, "Sources/Runner/Runner.swift", "struct Runner { let a: Int }\n")
        #expect(try await ProjectMemory.keep(project, queue: queue) == nil)

        try await commit(repo, "Sources/Tokens/Tokens.swift", "enum Tokens { case a }\n")
        let queued = try #require(try await ProjectMemory.keep(project, queue: queue))
        #expect(try await ProjectMemory.keep(project, queue: queue) == nil)

        let task = try #require(try await queue.task(queued))
        #expect(queued == "M-01")
        #expect(task.run == project.memory)
        #expect(task.priority == 4)
        #expect(task.goal.hasPrefix("Rebuild the project's memory brief"))
        #expect(try await queue.claim()?.id == "M-01")
    }

    @Test func aProjectWithNoBriefGetsItsFirstBuildQueued() async throws {
        let repo = try await TempRepo()
        let support = FileManager.default.temporaryDirectory.appending(path: "ProjectMemoryTests-\(UUID().uuidString)")
        defer { repo.remove(); try? FileManager.default.removeItem(at: support) }
        try FileManager.default.createDirectory(at: support, withIntermediateDirectories: true)
        let queue = try TaskQueue(at: support.appending(path: "queue.sqlite"))
        let project = try await SwiftProject.picked(repo.url, taken: [])

        #expect(try await ProjectMemory.keep(project, queue: queue) == "M-01")
        #expect(try await queue.task("M-01")?.goal.hasPrefix("Build the project's memory brief") == true)
        #expect(try await ProjectMemory.keep(project, queue: queue) == nil)
    }

    @Test func youCanAskForARebuildAnyTime() async throws {
        let support = FileManager.default.temporaryDirectory.appending(path: "ProjectMemoryTests-\(UUID().uuidString)")
        defer { try? FileManager.default.removeItem(at: support) }
        try FileManager.default.createDirectory(at: support, withIntermediateDirectories: true)
        let queue = try TaskQueue(at: support.appending(path: "queue.sqlite"))
        try await queue.add(QueuedTask(id: "M-01", goal: "Old build", doneMeans: "done", state: .done))
        let project = SwiftProject(id: "p", name: "P", folder: "/nowhere")

        #expect(try await ProjectMemory.rebuild(project, queue: queue) == "M-02")
        #expect(try await ProjectMemory.rebuild(project, queue: queue) == nil)
    }
}
