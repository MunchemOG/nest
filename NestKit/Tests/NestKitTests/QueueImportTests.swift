import Foundation
import Testing
@testable import NestKit

struct QueueImportTests {
    static let file = QueueFile(text: """
    | id | goal | done_means | needs |
    | --- | --- | --- | --- |
    | T9-01 | One | One passes | Phase 1 |
    | T9-02 | Two | Two passes | T9-01 |
    | T9-03 | Three | Three passes | T9-01, T9-02 |
    | T9-04 | Four | Four passes | all |
    """)

    func queue() throws -> (TaskQueue, URL) {
        let url = FileManager.default.temporaryDirectory.appending(path: "nest-import-\(UUID().uuidString).sqlite")
        return (try TaskQueue(at: url), url)
    }

    @Test func everyTaskIsAddedInOrderWithItsNeedsAndMergedOnesAreDone() async throws {
        let (queue, url) = try queue()
        defer { try? FileManager.default.removeItem(at: url) }

        let added = try await QueueImport.add(Self.file, merged: ["T9-01"], to: queue)

        #expect(added == ["T9-01", "T9-02", "T9-03", "T9-04"])
        let tasks = try await queue.tasks()
        #expect(tasks.map(\.id) == added)
        #expect(tasks.map(\.state) == [.done, .queued, .queued, .queued])
        #expect(tasks.map(\.needs) == [[], ["T9-01"], ["T9-01", "T9-02"], ["T9-01", "T9-02", "T9-03"]])
        #expect(tasks[1].goal == "Two")
        #expect(tasks[1].doneMeans == "Two passes")
        #expect(tasks.allSatisfy { $0.source == .you })
    }

    @Test func tasksAlreadyInTheQueueAreLeftAsTheyAre() async throws {
        let (queue, url) = try queue()
        defer { try? FileManager.default.removeItem(at: url) }
        try await queue.add(QueuedTask(id: "T9-02", goal: "Two, by chat", doneMeans: "Chat", state: .held))

        let added = try await QueueImport.add(Self.file, merged: [], to: queue)

        #expect(added == ["T9-01", "T9-03", "T9-04"])
        #expect(try await queue.task("T9-02")?.goal == "Two, by chat")
        #expect(try await queue.task("T9-02")?.state == .held)
    }

    @Test func theMergedTasksAreTheTaskBranchesMergedIntoTheBase() async throws {
        let repo = try await TempRepo()
        defer { repo.remove() }
        for id in ["T9-01", "T9-02"] {
            try await repo.git("switch", "-q", "-c", "task/\(id)")
            try id.write(to: repo.url.appending(path: "\(id).txt"), atomically: true, encoding: .utf8)
            try await repo.git("add", ".")
            try await repo.git("commit", "-q", "-m", "\(id): Add it")
            try await repo.git("switch", "-q", "main")
        }
        try await repo.git("merge", "-q", "--no-ff", "task/T9-01", "-m", "Merge branch 'task/T9-01'")

        #expect(try await QueueImport.merged(in: repo.url, base: "main") == ["T9-01"])
    }
}
