import Testing
@testable import NestKit

struct SummaryBlockTests {
    @Test func readsEveryLineOfTheBlock() throws {
        let text = """
        I built the thing.

        ```
        Result: held
        Did: Tried to add the queue.
        Tests: 212/214, 3 new
        Files: Queue.swift, QueueTests.swift
        Noticed: The README is one line.
        Next: S2-03, needs not met
        If held: Two snapshot tests fail; likely a font change; fairly confident.
        ```
        """
        let block = try #require(SummaryBlock(in: text))
        #expect(block.result == .held)
        #expect(block.did == "Tried to add the queue.")
        #expect(block.tests == "212/214, 3 new")
        #expect(block.files == "Queue.swift, QueueTests.swift")
        #expect(block.noticed == "The README is one line.")
        #expect(block.next == "S2-03, needs not met")
        #expect(block.ifHeld == "Two snapshot tests fail; likely a font change; fairly confident.")
    }

    @Test func aDoneBlockNeedsNoIfHeldLine() throws {
        let block = try #require(SummaryBlock(in: "Result: done\nDid: It.\nTests: 3/3, 1 new\n"))
        #expect(block.result == .done)
        #expect(block.ifHeld == nil)
        #expect(block.noticed == nil)
    }

    @Test func theLastBlockWins() throws {
        let text = "Result: held\nDid: First try.\n\nSecond go.\n\nResult: done\nDid: Second try.\n"
        let block = try #require(SummaryBlock(in: text))
        #expect(block.result == .done)
        #expect(block.did == "Second try.")
    }

    @Test func linesThatRunOnAreJoined() throws {
        let text = "Result: done\nDid: It.\nFiles: A.swift,\n  B.swift\nNoticed: nothing\n"
        let block = try #require(SummaryBlock(in: text))
        #expect(block.files == "A.swift, B.swift")
        #expect(block.noticed == "nothing")
    }

    @Test func textWithNoResultLineHasNoBlock() {
        #expect(SummaryBlock(in: "All finished, everything passes!") == nil)
        #expect(SummaryBlock(in: "") == nil)
    }

    @Test func anUnknownResultIsNoBlock() {
        #expect(SummaryBlock(in: "Result: splendid\nDid: It.\n") == nil)
        #expect(SummaryBlock(in: "Result: done | held | unclear\nDid: <one sentence>\n") == nil)
    }
}
