import Foundation
import Testing
@testable import NestKit

struct UndoAskTests {
    static func event(_ id: String, kind: EventKind, target: String? = nil, summary: String = "Wren moved a.txt to Notes", undo: Bool = true) -> NestEvent {
        NestEvent(
            id: id,
            ts: Date(timeIntervalSince1970: 1_000),
            sender: .bird(.wren),
            kind: kind,
            topic: .wrenFileMoved,
            summary: summary,
            data: target.map { ["target": .string($0)] } ?? [:],
            undo: undo ? EventUndo(op: "file.move", args: [:]) : nil,
            causedBy: nil,
            attention: .none
        )
    }

    @Test func askingToUndoNamesTheTarget() {
        let action = Self.event("evt_A", kind: .action)
        let ask = NestEvent.undoAsked(target: action, at: Date(timeIntervalSince1970: 2_000), id: "evt_ASK")
        #expect(ask.id == "evt_ASK")
        #expect(ask.sender == .you)
        #expect(ask.kind == .ask)
        #expect(ask.topic == .youUndoAsked)
        #expect(ask.data == ["target": .string("evt_A")])
        #expect(ask.undo == nil)
        #expect(ask.attention == .none)
        #expect(ask.summary.hasPrefix("You asked to undo"))
    }

    @Test func askingToRedoTargetsTheUndoEvent() {
        let undo = Self.event("evt_U", kind: .undo, target: "evt_A")
        let ask = NestEvent.undoAsked(target: undo, at: .now, id: "evt_ASK")
        #expect(ask.topic == .youUndoAsked)
        #expect(ask.data == ["target": .string("evt_U")])
        #expect(ask.summary.hasPrefix("You asked to redo"))
    }

    @Test func summariesStayWithinNinetyCharacters() {
        let long = Self.event("evt_A", kind: .action, summary: "Wren " + String(repeating: "moved a very long file name ", count: 6))
        #expect(NestEvent.undoAsked(target: long, at: .now, id: "evt_ASK").summary.count <= 90)
    }

    @Test func theChoiceFollowsTheKindAndWhetherItIsUndone() {
        #expect(UndoChoice(for: Self.event("a", kind: .action), isUndone: false) == .undo)
        #expect(UndoChoice(for: Self.event("a", kind: .note), isUndone: false) == .undo)
        #expect(UndoChoice(for: Self.event("a", kind: .action), isUndone: true) == .none)
        #expect(UndoChoice(for: Self.event("u", kind: .undo, target: "a"), isUndone: false) == .redo)
        #expect(UndoChoice(for: Self.event("u", kind: .undo, target: "a"), isUndone: true) == .none)
        #expect(UndoChoice(for: Self.event("s", kind: .signal, undo: false), isUndone: false) == .none)
        #expect(UndoChoice(for: Self.event("f", kind: .action, undo: false), isUndone: false) == .none)
    }

    @Test func theLedgerFollowsUndoAndRedo() {
        let action = Self.event("A", kind: .action)
        let undo = Self.event("U", kind: .undo, target: "A")
        let redo = Self.event("R", kind: .undo, target: "U")
        #expect(UndoLedger(events: [action]).isUndone("A") == false)
        #expect(UndoLedger(events: [action, undo]).isUndone("A"))
        let redone = UndoLedger(events: [action, undo, redo])
        #expect(redone.isUndone("A") == false)
        #expect(redone.isUndone("U"))
        #expect(redone.isUndone("R") == false)
    }

    @Test func theDemoDayUndoesOnlyTheN114Merge() throws {
        let events = try DemoDay.events()
        let ledger = UndoLedger(events: events)
        #expect(events.filter { ledger.isUndone($0.id) }.map(\.summary) == ["Swift merged N1-14 with 9 new tests"])
    }

    @Test func eventIdsAreUlidsThatSortByTime() {
        var random = PetRandom(seed: 7)
        let early = EventID.make(at: Date(timeIntervalSince1970: 1_700_000_000), using: &random)
        let late = EventID.make(at: Date(timeIntervalSince1970: 1_700_000_001), using: &random)
        #expect(early.hasPrefix("evt_"))
        #expect(early.count == 30)
        #expect(early < late)
        let crockford = Set("0123456789ABCDEFGHJKMNPQRSTVWXYZ")
        #expect(early.dropFirst(4).allSatisfy { crockford.contains($0) })
    }

    @Test func aDemoDayIdDecodesToItsOwnTime() throws {
        let first = try #require(try DemoDay.events().first)
        let rebuilt = EventID.timePart(at: first.ts)
        #expect(first.id.dropFirst(4).hasPrefix(rebuilt))
    }
}
