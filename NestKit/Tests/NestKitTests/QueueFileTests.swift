import Foundation
import Testing
@testable import NestKit

struct QueueFileTests {
    /// The repository's `docs/queue.md`, found from this file's place in the repo.
    static let url = URL(fileURLWithPath: #filePath)
        .deletingLastPathComponent()
        .deletingLastPathComponent()
        .deletingLastPathComponent()
        .deletingLastPathComponent()
        .appending(path: "docs/queue.md")

    @Test func readsTaskRowsAndNothingElse() {
        let text = """
        # Queue

        Some words about S2-01 that are not a row.

        | id | goal | done_means | needs |
        | --- | --- | --- | --- |
        | T9-01 | A greeting file | `greeting.txt` says hello | Phase 1 |
        | T9-02 | A farewell file | It says goodbye | T9-01, T9-00 |
        """
        let tasks = QueueFile(text: text).tasks
        #expect(tasks.map(\.id) == ["T9-01", "T9-02"])
        #expect(tasks[0].goal == "A greeting file")
        #expect(tasks[0].doneMeans == "`greeting.txt` says hello")
        #expect(tasks[0].needs == "Phase 1")
        #expect(tasks[1].needs == "T9-01, T9-00")
    }

    @Test func findsATaskByItsID() {
        let file = QueueFile(text: "| T9-01 | A greeting file | It says hello | nothing |\n")
        #expect(file.task("T9-01")?.goal == "A greeting file")
        #expect(file.task("T9-02") == nil)
    }

    @Test func theRealQueueHoldsThisTask() throws {
        let file = try QueueFile(contentsOf: Self.url)
        let task = try #require(file.task("S2-01"))
        #expect(task.goal == "Manual runner: one task becomes a tested branch while you watch")
        #expect(task.doneMeans == "One real task ends on its own branch with passing tests and the summary block")
        #expect(task.needs == "Phase 1")
        #expect(file.task("S2-16") != nil)
        #expect(file.task("N1-01") != nil)
    }
}
