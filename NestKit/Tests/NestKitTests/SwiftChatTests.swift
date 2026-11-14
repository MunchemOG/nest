import Testing
@testable import NestKit

struct SwiftChatTests {
    @Test func readsATaskWithItsTest() {
        let ask = SwiftChat.task(in: "Add a task: show the queue count on Home. Done means: a test sees 3 when 3 are queued")
        #expect(ask == .task(goal: "Show the queue count on Home", doneMeans: "A test sees 3 when 3 are queued"))
        #expect(SwiftChat.task(in: "add task show the count, done means the count test passes")
                == .task(goal: "Show the count", doneMeans: "The count test passes"))
    }

    @Test func aTaskWithNoTestIsFlaggedNotQueued() {
        #expect(SwiftChat.task(in: "Add a task: make Home nicer") == .needsTest(goal: "Make Home nicer"))
    }

    @Test func otherMessagesAreNotTasks() {
        #expect(SwiftChat.task(in: "How did last night go?") == nil)
    }

    @Test func idsCountUpFromTheLastOneYouAdded() {
        #expect(SwiftChat.nextID(after: []) == "Y-01")
        #expect(SwiftChat.nextID(after: ["S2-01", "Y-01", "Y-07", "C1-02"]) == "Y-08")
    }
}
