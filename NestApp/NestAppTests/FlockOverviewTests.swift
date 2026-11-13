import NestKit
import SwiftUI
import Testing
@testable import NestApp

@MainActor
struct FlockOverviewTests {
    static func event(_ bird: Bird, _ kind: EventKind, at seconds: TimeInterval) -> NestEvent {
        NestEvent(
            id: "evt_\(bird)_\(seconds)", ts: Date(timeIntervalSince1970: seconds), sender: .bird(bird), kind: kind,
            topic: .wrenFileMoved, summary: "\(bird.name) did something", data: [:],
            undo: kind == .signal ? nil : EventUndo(op: "file.move", args: [:]), causedBy: nil, attention: .none
        )
    }

    @Test func aNewActionMakesThatBirdReactOnce() {
        let model = FlockModel()
        model.receive(Self.event(.wren, .action, at: 100))
        #expect(model.reactions(of: .wren) == 1)
        for bird in Bird.allCases where bird != .wren {
            #expect(model.reactions(of: bird) == 0, "\(bird) reacted")
        }
    }

    @Test func signalsDoNotMakeABirdReact() {
        let model = FlockModel()
        model.receive(Self.event(.owl, .signal, at: 100))
        #expect(model.reactions(of: .owl) == 0)
        #expect(model.state[.owl].doing == "Owl did something")
    }

    @Test func undosAndNotesAreActionsToo() {
        let model = FlockModel()
        model.receive(Self.event(.swift, .undo, at: 100))
        model.receive(Self.event(.magpie, .note, at: 101))
        #expect(model.reactions(of: .swift) == 1)
        #expect(model.reactions(of: .magpie) == 1)
    }

    @Test func eachActionIsOneMoreReaction() {
        let model = FlockModel()
        for second in 0..<3 { model.receive(Self.event(.crow, .action, at: TimeInterval(second))) }
        #expect(model.reactions(of: .crow) == 3)
    }

    @Test func statusIsReadAtTheLatestEventsTime() {
        let model = FlockModel()
        model.receive(Self.event(.wren, .action, at: 0))
        model.receive(Self.event(.owl, .signal, at: BirdState.activeWindow + 60))
        #expect(model.status(of: .wren) == .resting)
        #expect(model.status(of: .owl) == .active)
        #expect(model.status(of: .peacock) == .asleep)
    }

    @Test func listeningReplaysASourceIntoTheModel() async throws {
        let model = FlockModel()
        let source = try ReplaySource.demoDay(clock: ImmediateClock(), speed: 1)
        await model.listen(to: source)
        #expect(model.state == FlockState(events: try DemoDay.events()))
    }

    @Test func theOverviewShowsEveryBirdInFlockOrder() {
        #expect(FlockOverview(model: FlockModel()).birds == Bird.allCases)
    }

    @Test func avatarsFollowStatus() {
        #expect(BirdAvatarState(.active) == .active)
        #expect(BirdAvatarState(.paused) == .paused)
        #expect(BirdAvatarState(.resting) == .resting)
        #expect(BirdAvatarState(.asleep) == .asleep)
    }

    @Test func theDemoDayOverviewMatchesItsSnapshot() throws {
        let model = FlockModel()
        for event in try DemoDay.events() { model.receive(event) }
        try Snapshot.expect(FlockOverview(model: model).frame(width: NestSpace.s10 * 4), named: "flock-overview-demo-day")
    }
}

/// A clock that never waits, so a replay runs at once.
struct ImmediateClock: Clock {
    var now: ContinuousClock.Instant { .now }
    var minimumResolution: Duration { .zero }
    func sleep(until deadline: ContinuousClock.Instant, tolerance: Duration?) async throws {}
}
