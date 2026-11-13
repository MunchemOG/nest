import Foundation
import Testing
@testable import NestKit

struct TaskQueueTests {
    let folder = FileManager.default.temporaryDirectory.appending(path: "TaskQueueTests-\(UUID().uuidString)")

    func queue() throws -> TaskQueue {
        try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        return try TaskQueue(at: folder.appending(path: "queue.sqlite"))
    }

    func task(_ id: String, priority: Int = 0, needs: [String] = [], source: QueueSource = .you) -> QueuedTask {
        QueuedTask(id: id, goal: "Goal of \(id)", doneMeans: "Test of \(id)", priority: priority, needs: needs, source: source)
    }

    @Test func addsOrdersClaimsAndFinishesTasksRespectingNeeds() async throws {
        let queue = try queue()
        try await queue.add(task("T-01"))
        try await queue.add(task("T-02", needs: ["T-01"]))
        try await queue.add(task("T-03", priority: 5))
        try await queue.add(task("T-04", priority: 5, needs: ["T-03"], source: .crow))

        #expect(try await queue.tasks().map(\.id) == ["T-03", "T-04", "T-01", "T-02"])

        let first = try #require(try await queue.claim())
        #expect(first.id == "T-03")
        #expect(first.state == .claimed)
        // T-04 is next by priority, but it needs T-03, which is claimed, not done.
        let second = try #require(try await queue.claim())
        #expect(second.id == "T-01")
        // T-02 needs T-01 and T-04 needs T-03: nothing else is ready.
        #expect(try await queue.claim() == nil)

        try await queue.finish("T-03", as: .done)
        let third = try #require(try await queue.claim())
        #expect(third.id == "T-04")
        #expect(third.source == .crow)

        try await queue.finish("T-01", as: .held)
        #expect(try await queue.claim() == nil, "a held need is not a done need")

        try await queue.finish("T-04", as: .done)
        #expect(try await queue.tasks().map(\.state) == [.done, .done, .held, .queued])
    }

    @Test func everyFieldSurvivesReopeningTheFile() async throws {
        let url = folder.appending(path: "queue.sqlite")
        try await queue().add(task("T-01", priority: 2, needs: ["T-00", "S2-01"], source: .crow))
        let reopened = try TaskQueue(at: url)
        let saved = try #require(try await reopened.task("T-01"))
        #expect(saved == QueuedTask(id: "T-01", goal: "Goal of T-01", doneMeans: "Test of T-01", priority: 2,
                                    needs: ["T-00", "S2-01"], source: .crow, state: .queued))
    }

    @Test func aNeedThatIsNotInTheQueueDoesNotBlock() async throws {
        let queue = try queue()
        try await queue.add(task("T-02", needs: ["T-01"]))
        #expect(try await queue.claim()?.id == "T-02")
    }

    @Test func addingAnIDTwiceIsRefused() async throws {
        let queue = try queue()
        try await queue.add(task("T-01"))
        await #expect(throws: TaskQueueError.duplicate("T-01")) { try await queue.add(task("T-01")) }
    }

    @Test func finishingATaskThatIsNotClaimedIsRefused() async throws {
        let queue = try queue()
        try await queue.add(task("T-01"))
        await #expect(throws: TaskQueueError.notClaimed("T-01")) { try await queue.finish("T-01", as: .done) }
        await #expect(throws: TaskQueueError.notClaimed("T-09")) { try await queue.finish("T-09", as: .done) }
    }

    @Test func aTaskIsOnlyFinishedAsDoneOrHeld() async throws {
        let queue = try queue()
        try await queue.add(task("T-01"))
        _ = try await queue.claim()
        await #expect(throws: TaskQueueError.notAnEnd(.queued)) { try await queue.finish("T-01", as: .queued) }
    }

    @Test func twoQueuesOnOneFileNeverClaimTheSameTask() async throws {
        let url = folder.appending(path: "queue.sqlite")
        let one = try queue()
        let two = try TaskQueue(at: url)
        try await one.add(task("T-01"))
        try await one.add(task("T-02"))
        async let a = one.claim()
        async let b = two.claim()
        let claimed = try await [a, b].compactMap { $0?.id }
        #expect(Set(claimed) == ["T-01", "T-02"])
    }
}
