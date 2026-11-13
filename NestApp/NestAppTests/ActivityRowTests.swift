import NestKit
import SwiftUI
import Testing
@testable import NestApp

@MainActor
struct ActivityRowTests {
    static let chicago = TimeZone(identifier: "America/Chicago")!

    static func demo(_ summary: String) throws -> NestEvent {
        try #require(try DemoDay.events().first { $0.summary == summary })
    }

    final class Outbox {
        var events: [NestEvent] = []
    }

    @Test func tappingUndoPublishesAnUndoAskForThatEvent() throws {
        let merge = try Self.demo("Swift merged N1-13 with 17 new tests")
        let outbox = Outbox()
        ActivityRow(merge, isUndone: false) { outbox.events.append($0) }.tap()
        let ask = try #require(outbox.events.only)
        #expect(ask.topic == .youUndoAsked)
        #expect(ask.sender == .you)
        #expect(ask.data["target"] == .string(merge.id))
    }

    @Test func tappingRedoPublishesAnUndoAskForTheUndoEvent() throws {
        let rollback = try Self.demo("Swift rolled back the N1-14 merge")
        let outbox = Outbox()
        ActivityRow(rollback, isUndone: false) { outbox.events.append($0) }.tap()
        let ask = try #require(outbox.events.only)
        #expect(ask.topic == .youUndoAsked)
        #expect(ask.data["target"] == .string(rollback.id))
    }

    @Test func aRowWithNothingToReverseDoesNotPublish() throws {
        let outbox = Outbox()
        ActivityRow(try Self.demo("Owl saw Mithun sit down"), isUndone: false) { outbox.events.append($0) }.tap()
        #expect(outbox.events.isEmpty)
    }

    @Test func rowsOfferTheRightControl() throws {
        #expect(ActivityRow(try Self.demo("Swift merged N1-13 with 17 new tests"), isUndone: false) { _ in }.choice == .undo)
        #expect(ActivityRow(try Self.demo("Swift merged N1-14 with 9 new tests"), isUndone: true) { _ in }.choice == .none)
        #expect(ActivityRow(try Self.demo("Swift rolled back the N1-14 merge"), isUndone: false) { _ in }.choice == .redo)
        #expect(ActivityRow(try Self.demo("Owl saw Mithun sit down"), isUndone: false) { _ in }.choice == .none)
    }

    @Test func theMetaLineIsTheBirdAndTheTime() throws {
        let row = ActivityRow(try Self.demo("Swift merged N1-13 with 17 new tests"), isUndone: false) { _ in }
        #expect(row.meta(in: Self.chicago) == "Swift · 01:12")
    }

    @Test func everyRowKindMatchesItsSnapshot() throws {
        let cases: [(String, String, Bool)] = [
            ("undo", "Wren moved swerve-pod-v4.step to Robotics / CAD", false),
            ("undone", "Swift merged N1-14 with 9 new tests", true),
            ("redo", "Swift rolled back the N1-14 merge", false),
            ("signal", "Owl saw Mithun sit down", false),
        ]
        for (name, summary, undone) in cases {
            let row = ActivityRow(try Self.demo(summary), isUndone: undone) { _ in }
                .environment(\.timeZone, Self.chicago)
                .frame(width: NestSpace.s10 * 3)
            try Snapshot.expect(row, named: "activity-\(name)")
        }
    }
}

extension Array {
    /// The single element, or nil if there are none or several.
    var only: Element? { count == 1 ? first : nil }
}
