import Foundation
import Testing
@testable import NestKit

/// Swift keeps no memory of its own: each project relies on Claude Code's per-folder memory.
struct NoOwnMemoryTests {
    @Test func noPromptCarriesABriefAndNoNightQueuesABuild() async throws {
        let repo = try await TempRepo()
        let support = FileManager.default.temporaryDirectory.appending(path: "NoOwnMemoryTests-\(UUID().uuidString)")
        defer { repo.remove(); try? FileManager.default.removeItem(at: support) }
        let brief = repo.url.appending(path: ".nest/memory/README.md")
        try FileManager.default.createDirectory(at: brief.deletingLastPathComponent(), withIntermediateDirectories: true)
        try "# An old brief\n".write(to: brief, atomically: true, encoding: .utf8)
        try await repo.git("add", ".")
        try await repo.git("commit", "-q", "-m", "Old brief")
        try FileManager.default.createDirectory(at: support, withIntermediateDirectories: true)
        let project = try await SwiftProject.picked(repo.url, taken: [])
        try FileManager.default.createDirectory(at: project.queueFile(in: support).deletingLastPathComponent(),
                                                withIntermediateDirectories: true)
        try await TaskQueue(at: project.queueFile(in: support)).add(QueuedTask(id: "Y-01", goal: "The file", doneMeans: "It exists"))
        let presence = PresenceWatch()
        await presence.receive(.presenceChanged(to: "away", was: "here"))
        let night = SwiftNight(settings: SwiftSettings(limits: .standard, projects: [project]), folder: support,
                               session: try repo.script("session", ProjectsTests.session), presence: presence)

        _ = await night.tick()

        let prompt = try String(contentsOf: repo.url.appending(path: ".git/prompt-Y-01.txt"), encoding: .utf8)
        #expect(!prompt.contains("An old brief"))
        #expect(!prompt.contains(".nest/memory"))
        #expect(try await TaskQueue(at: project.queueFile(in: support)).tasks().map(\.id) == ["Y-01"])
    }
}
