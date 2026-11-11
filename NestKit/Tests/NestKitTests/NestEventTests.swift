import Foundation
import Testing
@testable import NestKit

struct NestEventTests {
    /// The envelope example from `docs/event-bus.md`, copied as written.
    static let contractExample = """
        {
          "id": "evt_01JCF8Q2X9M4",
          "ts": "2026-11-10T08:14:07-06:00",
          "bird": "wren",
          "kind": "action",
          "topic": "wren.file.moved",
          "summary": "Wren moved swerve-pod-v4.step to Robotics / CAD",
          "data": {"from": "~/Downloads/swerve-pod-v4.step", "to": "~/Mithu/Robotics/CAD/swerve-pod-v4.step", "rule": "ext+project", "confidence": 0.94},
          "undo": {"op": "file.move", "args": {"from": "~/Mithu/Robotics/CAD/swerve-pod-v4.step", "to": "~/Downloads/swerve-pod-v4.step"}},
          "caused_by": "evt_01JCF8PZ7T11",
          "attention": "none"
        }
        """

    @Test func contractExampleDecodesEveryField() throws {
        let event = try EventJSON.decode(Self.contractExample)
        #expect(event.id == "evt_01JCF8Q2X9M4")
        #expect(event.ts == Date(timeIntervalSince1970: 1_794_320_047))
        #expect(event.sender == .bird(.wren))
        #expect(event.kind == .action)
        #expect(event.topic == .wrenFileMoved)
        #expect(event.summary == "Wren moved swerve-pod-v4.step to Robotics / CAD")
        #expect(event.data == [
            "from": .string("~/Downloads/swerve-pod-v4.step"),
            "to": .string("~/Mithu/Robotics/CAD/swerve-pod-v4.step"),
            "rule": .string("ext+project"),
            "confidence": .number(0.94),
        ])
        #expect(event.undo == EventUndo(op: "file.move", args: [
            "from": .string("~/Mithu/Robotics/CAD/swerve-pod-v4.step"),
            "to": .string("~/Downloads/swerve-pod-v4.step"),
        ]))
        #expect(event.causedBy == "evt_01JCF8PZ7T11")
        #expect(event.attention == EventAttention.none)
    }

    @Test func nullUndoAndCauseDecodeAsNil() throws {
        let event = try EventJSON.decode(EventJSON.make())
        #expect(event.undo == nil)
        #expect(event.causedBy == nil)
    }

    @Test(arguments: [
        ("wren", EventSender.bird(.wren)),
        ("swift", .bird(.swift)),
        ("crow", .bird(.crow)),
        ("owl", .bird(.owl)),
        ("magpie", .bird(.magpie)),
        ("peacock", .bird(.peacock)),
        ("you", .you),
        ("app", .app),
    ])
    func everySenderDecodes(_ raw: String, _ expected: EventSender) throws {
        #expect(try EventJSON.decode(EventJSON.make(bird: raw)).sender == expected)
    }

    @Test(arguments: [
        ("signal", EventKind.signal),
        ("action", .action),
        ("undo", .undo),
        ("pitch", .pitch),
        ("report", .report),
        ("note", .note),
        ("ask", .ask),
    ])
    func everyKindDecodes(_ raw: String, _ expected: EventKind) throws {
        #expect(try EventJSON.decode(EventJSON.make(kind: raw)).kind == expected)
    }

    @Test(arguments: [
        ("none", EventAttention.none),
        ("inbox", .inbox),
        ("calm", .calm),
        ("ping", .ping),
    ])
    func everyAttentionDecodes(_ raw: String, _ expected: EventAttention) throws {
        #expect(try EventJSON.decode(EventJSON.make(attention: raw)).attention == expected)
    }

    @Test(arguments: [
        EventJSON.make(bird: "heron"),
        EventJSON.make(kind: "shout"),
        EventJSON.make(attention: "loud"),
        EventJSON.make(ts: "yesterday"),
        EventJSON.make(ts: "2026-11-10T08:14:07"),
        #"{"id": "evt_01JCF8Q2X9M4"}"#,
    ])
    func malformedEventsThrowInsteadOfCrashing(_ json: String) {
        #expect(throws: DecodingError.self) { try EventJSON.decode(json) }
    }

    @Test func timeKeepsItsOffset() throws {
        let central = try EventJSON.decode(EventJSON.make(ts: "2026-11-10T08:14:07-06:00"))
        let utc = try EventJSON.decode(EventJSON.make(ts: "2026-11-10T14:14:07Z"))
        #expect(central.ts == utc.ts)
    }

    @Test func fractionalSecondsDecode() throws {
        let event = try EventJSON.decode(EventJSON.make(ts: "2026-11-10T14:14:07.250Z"))
        #expect(event.ts == Date(timeIntervalSince1970: 1_794_320_047.25))
    }

    @Test func dataKeepsEveryJSONShape() throws {
        let data = #"{"tasks": ["N1-13", "N1-14"], "count": 3, "ok": true, "guess": null, "usage": {"percent": 41.5}}"#
        let event = try EventJSON.decode(EventJSON.make(data: data))
        #expect(event.data == [
            "tasks": .array([.string("N1-13"), .string("N1-14")]),
            "count": .number(3),
            "ok": .bool(true),
            "guess": .null,
            "usage": .object(["percent": .number(41.5)]),
        ])
    }
}
