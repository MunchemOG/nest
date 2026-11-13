import Foundation
import Testing
@testable import NestKit

struct AppAskTests {
    @Test func anAskNamesTheBirdAndTheWords() {
        let ask = NestEvent.appAsk(to: "wren", text: "Focus mode", id: "evt_A")
        #expect(ask.topic == .appAskSent)
        #expect(ask.sender == .app)
        #expect(ask.kind == .ask)
        #expect(ask.undo == nil)
        #expect(ask.data == ["to": .string("wren"), "text": .string("Focus mode")])
        #expect(ask.summary == "Nest asked Wren: Focus mode")
    }

    @Test func askSummariesStayShort() {
        let ask = NestEvent.appAsk(to: "everyone", text: String(repeating: "tidy ", count: 40))
        #expect(ask.summary.count <= NestEvent.summaryMaxLength)
        #expect(ask.summary.hasPrefix("Nest asked Everyone: "))
    }
}
