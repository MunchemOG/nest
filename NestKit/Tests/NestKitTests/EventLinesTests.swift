import Foundation
import Testing
@testable import NestKit

struct EventLinesTests {
    @Test func decodesOneEventPerLineAndSkipsBlankLines() throws {
        let text = [
            EventJSON.make(topic: "wren.file.skipped"),
            "",
            EventJSON.make(bird: "owl", topic: "owl.flow.changed"),
            "",
        ].joined(separator: "\n")
        let events = try NestEvent.lines(Data(text.utf8))
        #expect(events.map(\.topic) == [.wrenFileSkipped, .owlFlowChanged])
    }

    @Test func aBadLineThrowsWithItsLineNumber() {
        let text = [EventJSON.make(), EventJSON.make(), "{not json"].joined(separator: "\n")
        #expect(throws: NestEvent.LineError.self) { try NestEvent.lines(Data(text.utf8)) }
        do {
            _ = try NestEvent.lines(Data(text.utf8))
        } catch let error as NestEvent.LineError {
            #expect(error.line == 3)
        } catch {
            Issue.record("unexpected error \(error)")
        }
    }
}
