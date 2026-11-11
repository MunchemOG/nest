import Foundation
import Testing
@testable import NestKit

struct FlockStateTests {
    static func time(_ text: String) throws -> Date {
        try Date(text, strategy: .iso8601)
    }

    static func event(_ bird: String, _ kind: String, _ topic: String, at ts: String, data: String = "{}") throws -> NestEvent {
        try EventJSON.decode(EventJSON.make(bird: bird, kind: kind, topic: topic, ts: ts, data: data))
    }

    struct Expected: Sendable, CustomTestStringConvertible {
        let bird: Bird
        let status: BirdStatus
        let latestAction: String?
        let doing: String

        var testDescription: String { bird.name }
    }

    /// Read off `demo-day.jsonl` by hand, at 22:20, the time of its last event.
    static let endOfDemoDay: [Expected] = [
        Expected(bird: .wren, status: .resting, latestAction: "Wren set the Night look: harbour, dark, lagoon accent",
                 doing: "Wren set the Night look: harbour, dark, lagoon accent"),
        Expected(bird: .swift, status: .active, latestAction: "Swift rolled back the N1-14 merge",
                 doing: "Swift started a night run on N1-14 and N1-15"),
        Expected(bird: .crow, status: .resting, latestAction: nil,
                 doing: "Crow heard back on the report card idea: build"),
        Expected(bird: .owl, status: .resting, latestAction: "Owl hid Safari after 12 minutes of YouTube",
                 doing: "Owl saw Mithun leave for the night"),
        Expected(bird: .magpie, status: .active, latestAction: "Magpie wrote up today in the daily note",
                 doing: "Magpie wrote up today in the daily note"),
        Expected(bird: .peacock, status: .paused, latestAction: nil,
                 doing: "Peacock made a post kit: the shell replays a day"),
    ]

    @Test(arguments: endOfDemoDay)
    func replayingTheDemoDayGivesEachBirdItsExpectedState(_ expected: Expected) async throws {
        var state = FlockState()
        for await event in try ReplaySource.demoDay(clock: RecordingClock(), speed: 60).events() {
            state.apply(event)
        }
        let bird = state[expected.bird]
        #expect(bird.status(at: try Self.time("2026-11-10T22:20:00-06:00")) == expected.status)
        #expect(bird.latestAction?.summary == expected.latestAction)
        #expect(bird.doing == expected.doing)
    }

    @Test func withNoEventsEveryBirdIsAsleep() throws {
        let state = FlockState()
        let now = try Self.time("2026-11-10T12:00:00-06:00")
        for bird in Bird.allCases {
            #expect(state[bird].status(at: now) == .asleep)
            #expect(state[bird].doing == nil)
            #expect(state[bird].latestAction == nil)
        }
    }

    @Test func activeLastsTenMinutesAfterTheBirdsLatestEvent() throws {
        let state = FlockState(events: [try Self.event("wren", "signal", "wren.file.skipped", at: "2026-11-10T12:00:00-06:00")])
        #expect(state[.wren].status(at: try Self.time("2026-11-10T12:10:00-06:00")) == .active)
        #expect(state[.wren].status(at: try Self.time("2026-11-10T12:10:01-06:00")) == .resting)
    }

    @Test func pausingWinsOverActiveAndResumingUndoesIt() throws {
        let heard = try Self.event("crow", "signal", "crow.friction.seen", at: "2026-11-10T12:00:00-06:00")
        let paused = try Self.event("app", "signal", "app.bird.paused", at: "2026-11-10T12:01:00-06:00", data: #"{"bird": "crow"}"#)
        let resumed = try Self.event("app", "signal", "app.bird.resumed", at: "2026-11-10T12:02:00-06:00", data: #"{"bird": "crow"}"#)
        let now = try Self.time("2026-11-10T12:03:00-06:00")
        #expect(FlockState(events: [heard, paused])[.crow].status(at: now) == .paused)
        #expect(FlockState(events: [heard, paused, resumed])[.crow].status(at: now) == .active)
        #expect(FlockState(events: [heard, paused])[.owl].status(at: now) == .asleep)
    }

    @Test func aPausedBirdThatWasNeverHeardIsStillPaused() throws {
        let paused = try Self.event("app", "signal", "app.bird.paused", at: "2026-11-10T12:00:00-06:00", data: #"{"bird": "owl"}"#)
        #expect(FlockState(events: [paused])[.owl].status(at: try Self.time("2026-11-10T12:00:00-06:00")) == .paused)
    }

    @Test func latestActionIgnoresEventsThatChangedNothing() throws {
        let moved = try Self.event("wren", "action", "wren.file.moved", at: "2026-11-10T12:00:00-06:00")
        let skipped = try Self.event("wren", "signal", "wren.file.skipped", at: "2026-11-10T12:05:00-06:00")
        let state = FlockState(events: [moved, skipped])
        #expect(state[.wren].latestAction == moved)
        #expect(state[.wren].doing == skipped.summary)
    }

    @Test func eventsFromYouAndTheAppBelongToNoBird() throws {
        let asked = try Self.event("you", "ask", "you.undo.asked", at: "2026-11-10T12:00:00-06:00")
        let sent = try Self.event("app", "ask", "app.ask.sent", at: "2026-11-10T12:00:00-06:00", data: #"{"to": "wren", "text": "Tidy up"}"#)
        let state = FlockState(events: [asked, sent])
        let now = try Self.time("2026-11-10T12:00:00-06:00")
        for bird in Bird.allCases {
            #expect(state[bird].status(at: now) == .asleep)
        }
    }

    @Test func pausingSomethingThatIsNotABirdChangesNothing() throws {
        let paused = try Self.event("app", "signal", "app.bird.paused", at: "2026-11-10T12:00:00-06:00", data: #"{"bird": "heron"}"#)
        #expect(FlockState(events: [paused]) == FlockState())
    }
}
