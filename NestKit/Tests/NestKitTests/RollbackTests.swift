import Foundation
import Testing
@testable import NestKit

struct RollbackTests {
    /// Builds whichever task its prompt names; T9-02 also leaves `broken.txt`, which only the main suite looks for.
    static let session = """
    id=$(printf '%s' "$1" | grep -o 'Do task [A-Z0-9-]*' | cut -d' ' -f3)
    echo "$id" > "$id.txt"
    if [ "$id" = T9-02 ]; then echo oops > broken.txt; fi
    git add -A
    git commit -q -m "$id: Add $id.txt"
    echo "Result: done"
    echo "Did: Added $id.txt."
    echo "Tests: 1/1, 1 new"
    echo "Files: $id.txt"
    echo "Noticed: nothing"
    echo "Next: none"
    """

    @Test func aDeliberatelyBrokenTaskIsCaughtAndRolledBackWithNoHelp() async throws {
        let repo = try await TempRepo()
        defer { repo.remove() }
        let queue = try TaskQueue(at: repo.url.appending(path: ".git/queue.sqlite"))
        for id in ["T9-01", "T9-02", "T9-03"] {
            try await queue.add(QueuedTask(id: id, goal: "The file \(id).txt", doneMeans: "\(id).txt exists"))
        }
        let published = Published()
        let runner = QueueRunner(
            queue: queue,
            runner: ManualRunner(repository: repo.url, session: try repo.script("session", Self.session),
                                 tests: try repo.script("unit", "echo 'unit tests passed'")),
            merger: AutoMerge(repository: repo.url),
            mainTests: try repo.script("all", "test ! -f broken.txt"),
            publish: published.add
        )

        let outcomes = try await runner.runUntilEmpty()

        #expect(outcomes.map(\.task.id) == ["T9-01", "T9-02", "T9-03"])
        #expect(try await queue.tasks().map(\.state) == [.done, .held, .done])
        #expect(try await repo.git("show", "main:T9-01.txt") == "T9-01")
        #expect(try await repo.git("show", "main:T9-03.txt") == "T9-03")
        #expect(try await repo.git("ls-tree", "--name-only", "main").contains("broken.txt") == false)
        #expect(try await repo.git("ls-tree", "--name-only", "main").contains("T9-02.txt") == false)

        let events = published.events
        #expect(events.map(\.topic) == [.swiftTaskMerged, .swiftTaskMerged, .swiftMergeRolledBack, .swiftTaskMerged])
        let rollback = events[2]
        #expect(rollback.kind == .undo)
        #expect(rollback.data["target"] == .string(events[1].id))
        #expect(rollback.data["why"] == .string("The whole suite failed on main after the merge."))
        #expect(rollback.attention == .inbox)
        #expect(rollback.summary == "Swift undid the merge of T9-02")
    }

    @Test func withoutAMergerNothingIsMerged() async throws {
        let repo = try await TempRepo()
        defer { repo.remove() }
        let queue = try TaskQueue(at: repo.url.appending(path: ".git/queue.sqlite"))
        try await queue.add(QueuedTask(id: "T9-01", goal: "One", doneMeans: "One"))
        let runner = QueueRunner(queue: queue, runner: ManualRunner(
            repository: repo.url, session: try repo.script("session", Self.session), tests: ["true"]))

        _ = try await runner.runUntilEmpty()

        #expect(try await repo.git("log", "--format=%s", "main") == "Start")
    }
}

/// Collects the events a runner publishes.
final class Published: @unchecked Sendable {
    private let lock = NSLock()
    private var stored: [NestEvent] = []

    var events: [NestEvent] { lock.withLock { stored } }

    @Sendable func add(_ event: NestEvent) async {
        lock.withLock { stored.append(event) }
    }
}
