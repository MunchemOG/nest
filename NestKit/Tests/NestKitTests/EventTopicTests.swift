import Testing
@testable import NestKit

struct EventTopicTests {
    /// Every row of the Topics table in `docs/event-bus.md`, with its kind.
    static let contractTopics: [(String, EventKind)] = [
        ("owl.presence.changed", .signal),
        ("owl.flow.changed", .signal),
        ("owl.distraction.noticed", .signal),
        ("owl.nudge.given", .action),
        ("owl.screen.locked", .action),
        ("owl.gesture.done", .action),
        ("wren.file.moved", .action),
        ("wren.file.renamed", .action),
        ("wren.file.skipped", .signal),
        ("wren.folder.created", .action),
        ("wren.look.changed", .action),
        ("wren.mode.changed", .action),
        ("wren.workspace.restored", .action),
        ("swift.run.started", .signal),
        ("swift.run.finished", .signal),
        ("swift.task.merged", .action),
        ("swift.task.held", .signal),
        ("swift.task.failed", .signal),
        ("swift.merge.rolled_back", .undo),
        ("swift.report.ready", .report),
        ("crow.friction.seen", .signal),
        ("crow.pitch.made", .pitch),
        ("crow.pitch.answered", .signal),
        ("magpie.note.written", .note),
        ("magpie.note.linked", .note),
        ("magpie.lesson.learned", .note),
        ("magpie.memory.forgotten", .action),
        ("peacock.win.seen", .signal),
        ("peacock.clip.saved", .action),
        ("peacock.kit.ready", .report),
        ("you.undo.asked", .ask),
        ("you.correction.made", .signal),
        ("app.ask.sent", .ask),
        ("app.bird.paused", .signal),
        ("app.bird.resumed", .signal),
    ]

    @Test(arguments: contractTopics)
    func everyContractTopicDecodesAsKnown(_ topic: String, _ kind: EventKind) throws {
        let bird = String(topic.prefix { $0 != "." })
        let event = try EventJSON.decode(EventJSON.make(bird: bird, kind: kind.rawValue, topic: topic))
        #expect(event.topic.rawValue == topic)
        #expect(event.topic.isKnown)
        #expect(event.kind == kind)
    }

    @Test func knownTopicsAreExactlyTheContractTopics() {
        #expect(Set(EventTopic.known.map(\.rawValue)) == Set(Self.contractTopics.map(\.0)))
    }

    @Test func unknownTopicIsKeptNotRejected() throws {
        let event = try EventJSON.decode(EventJSON.make(bird: "owl", topic: "owl.tea.brewed"))
        #expect(event.topic.rawValue == "owl.tea.brewed")
        #expect(event.topic.isKnown == false)
        #expect(event.sender == .bird(.owl))
    }

    @Test func namedTopicsMatchTheirText() {
        #expect(EventTopic.wrenFileMoved.rawValue == "wren.file.moved")
        #expect(EventTopic.swiftMergeRolledBack.rawValue == "swift.merge.rolled_back")
        #expect(EventTopic.appBirdResumed.rawValue == "app.bird.resumed")
    }
}
