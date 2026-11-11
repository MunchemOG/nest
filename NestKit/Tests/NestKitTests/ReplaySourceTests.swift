import Foundation
import Testing
@testable import NestKit

struct ReplaySourceTests {
    static func collect(_ source: some FlockSource) async -> [NestEvent] {
        var received: [NestEvent] = []
        for await event in source.events() {
            received.append(event)
        }
        return received
    }

    @Test func replaysTheDemoDayInOrder() async throws {
        let source = try ReplaySource.demoDay(clock: RecordingClock(), speed: 60)
        let received = await Self.collect(source)
        #expect(received.count == 62)
        #expect(received.map(\.id) == (try DemoDay.events()).map(\.id))
    }

    @Test func waitsTheGapBetweenEventsDividedBySpeed() async throws {
        let events = try [
            "2026-11-10T08:00:00-06:00",
            "2026-11-10T08:01:00-06:00",
            "2026-11-10T08:04:00-06:00",
            "2026-11-10T08:04:00-06:00",
        ].map { try EventJSON.decode(EventJSON.make(ts: $0)) }
        let clock = RecordingClock()
        let received = await Self.collect(ReplaySource(events: events, clock: clock, speed: 60))
        #expect(received.count == 4)
        #expect(clock.sleeps == [.seconds(1), .seconds(3)])
    }

    @Test func anEmptySourceFinishesWithNoEvents() async {
        let received = await Self.collect(ReplaySource(events: [], clock: RecordingClock(), speed: 1))
        #expect(received.isEmpty)
    }

    @Test func eachListenerGetsTheWholeReplay() async throws {
        let source = try ReplaySource.demoDay(clock: RecordingClock(), speed: 60)
        let first = await Self.collect(source)
        let second = await Self.collect(source)
        #expect(first == second)
        #expect(first.count == 62)
    }
}
