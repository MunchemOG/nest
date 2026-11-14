import Foundation
import Testing
@testable import NestKit

struct ProjectsTests {
    /// A stand-in for Claude Code that builds the task its prompt (the last argument) names.
    static let session = """
    for prompt in "$@"; do :; done
    id=$(printf '%s' "$prompt" | grep -o 'Do task [A-Z0-9-]*' | cut -d' ' -f3)
    printf '%s' "$prompt" > ".git/prompt-$id.txt"
    echo "$id" > "$id.txt"
    git add "$id.txt"
    git commit -q -m "$id: Add $id.txt"
    echo "Result: done"
    echo "Did: Added $id.txt."
    echo "Tests: 1/1, 1 new"
    """

    func temp() throws -> URL {
        let url = FileManager.default.temporaryDirectory.appending(path: "ProjectsTests-\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
        return url
    }

    @Test func swiftStartsWithTheNestByItsStrictRules() throws {
        let folder = try temp()
        defer { try? FileManager.default.removeItem(at: folder) }
        let store = SwiftSettingsStore(at: folder.appending(path: "settings.json"), nest: URL(fileURLWithPath: "/Users/someone/Developer/nest"))

        let settings = try store.load()

        #expect(settings.limits == .standard)
        #expect(settings.projects.count == 1)
        let nest = try #require(settings.projects.first)
        #expect(nest.id == "nest")
        #expect(nest.name == "The Nest")
        #expect(nest.folder == "/Users/someone/Developer/nest")
        #expect(nest.tests == ["scripts/test.sh", "all"])
        #expect(nest.autoMerge)
        #expect(nest.strictChecks)
        #expect(nest.importsQueueFile)
        #expect(nest.defaults == .everyday)
        #expect(nest.memory == .deepest)
        #expect(nest.queueFile(in: folder) == folder.appending(path: "queue.sqlite"))
    }

    @Test func aFolderYouPickBecomesAProjectThatIsSaved() async throws {
        let folder = try temp()
        let repo = try await TempRepo()
        defer { try? FileManager.default.removeItem(at: folder); repo.remove() }
        try await repo.git("branch", "-m", "main", "trunk")
        let store = SwiftSettingsStore(at: folder.appending(path: "settings.json"), nest: URL(fileURLWithPath: "/n"))

        var settings = try store.load()
        let project = try await SwiftProject.picked(repo.url, taken: settings.projects.map(\.id))
        settings.projects.append(project)
        settings.limits.weeklyCap = 0.5
        try store.save(settings)

        let again = try store.load()
        #expect(again == settings)
        #expect(project.folder == repo.url.path)
        #expect(project.base == "trunk")
        #expect(project.tests == nil)
        #expect(!project.autoMerge)
        #expect(!project.strictChecks)
        #expect(!project.importsQueueFile)
        #expect(project.queueFile(in: folder) == folder.appending(path: "projects/\(project.id)/queue.sqlite"))
        let twin = try await SwiftProject.picked(repo.url, taken: again.projects.map(\.id))
        #expect(twin.id != project.id)
    }

    @Test func aFolderThatIsNotARepositoryIsRefused() async throws {
        let folder = try temp()
        defer { try? FileManager.default.removeItem(at: folder) }
        await #expect(throws: SwiftProjectError.notARepository(folder.path)) {
            try await SwiftProject.picked(folder, taken: [])
        }
    }

    @Test func aNightBuildsATaskInTwoReposAndOnlyTheTestedOneMerges() async throws {
        let support = try temp()
        let tested = try await TempRepo()
        let untested = try await TempRepo()
        defer { try? FileManager.default.removeItem(at: support); tested.remove(); untested.remove() }
        try await untested.git("rm", "-q", "CLAUDE.md")
        try await untested.git("commit", "-q", "-m", "No rules")
        let session = try tested.script("session", Self.session)

        var robotics = try await SwiftProject.picked(tested.url, taken: ["nest"])
        robotics.tests = try tested.script("tests", "echo '1 test passed'")
        robotics.autoMerge = true
        var physics = try await SwiftProject.picked(untested.url, taken: ["nest", robotics.id])
        physics.autoMerge = true
        let settings = SwiftSettings(limits: .standard, projects: [robotics, physics])
        for project in settings.projects {
            try FileManager.default.createDirectory(at: project.queueFile(in: support).deletingLastPathComponent(),
                                                    withIntermediateDirectories: true)
            try await TaskQueue(at: project.queueFile(in: support)).add(QueuedTask(id: "Y-01", goal: "The file", doneMeans: "It exists"))
        }
        let presence = PresenceWatch()
        await presence.receive(.presenceChanged(to: "away", was: "here"))
        let night = SwiftNight(settings: settings, folder: support, session: session, presence: presence)

        let runs = await night.tick()

        #expect(runs.map(\.project) == [robotics.id, physics.id])
        #expect(runs.allSatisfy { $0.error == nil })
        #expect(try await tested.git("log", "-1", "--format=%s", "main") == "Merge branch 'task/Y-01'")
        #expect(try await untested.git("log", "-1", "--format=%s", "main") == "No rules")
        #expect(try await untested.git("log", "-1", "--format=%s", "task/Y-01") == "Y-01: Add Y-01.txt")
        #expect(try await TaskQueue(at: physics.queueFile(in: support)).task("Y-01")?.state == .done)
        let prompt = try String(contentsOf: untested.url.appending(path: ".git/prompt-Y-01.txt"), encoding: .utf8)
        #expect(prompt.contains(SwiftProject.houseRules))
        #expect(prompt.contains("Do all the work yourself in this one session"))
    }

    @Test func withYouHereNoProjectStarts() async throws {
        let support = try temp()
        let repo = try await TempRepo()
        defer { try? FileManager.default.removeItem(at: support); repo.remove() }
        let project = try await SwiftProject.picked(repo.url, taken: [])
        let presence = PresenceWatch()
        await presence.receive(.presenceChanged(to: "here", was: "away"))
        let night = SwiftNight(settings: SwiftSettings(limits: .standard, projects: [project]), folder: support,
                               session: try repo.script("session", Self.session), presence: presence)

        #expect(await night.tick().isEmpty)
    }

    @Test func eachProjectsRunnerKeepsItsOwnRulesAndShare() async throws {
        let support = try temp()
        let repo = try await TempRepo()
        defer { try? FileManager.default.removeItem(at: support); repo.remove() }
        var project = try await SwiftProject.picked(repo.url, taken: [])
        project.share = 0.3
        project.defaults = RunSettings(model: .haiku, effort: .low, subagents: false)
        let limits = SwiftLimits(weeklyCap: 0.5, fiveHourCap: 0.8)
        let night = SwiftNight(settings: SwiftSettings(limits: limits, projects: [project]), folder: support,
                               session: ["claude"], presence: PresenceWatch())

        let runner = try await night.runner(for: project)

        #expect(runner.project == project.id)
        #expect(runner.merger == nil)
        #expect(runner.runner.defaults == project.defaults)
        #expect(runner.runner.repository.path == repo.url.path)
        #expect(runner.runner.base == "main")
        #expect(!runner.runner.checks)
        #expect(runner.budget?.rules.weeklyCap == 0.5)
        #expect(runner.budget?.rules.fiveHourCeiling == 0.8)
        #expect(runner.budget?.project == ProjectShare(project: project.id, share: 0.3))
    }
}
