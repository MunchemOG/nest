import Foundation
import Testing
@testable import NestKit

struct PetWorldTests {
    @Test func onlyRestingAndAsleepBirdsAreIdle() {
        #expect(PetWorld.fixture(busy: [.swift]).idleBirds == Set(Bird.allCases).subtracting([.swift]))
    }

    @Test func restingBirdsAreIdle() {
        var world = PetWorld.fixture(busy: [.crow])
        world.now += BirdState.activeWindow + 1
        #expect(world.idleBirds == Set(Bird.allCases))
    }

    @Test func pausedBirdsAreNotIdle() throws {
        var world = PetWorld.fixture()
        let paused = try EventJSON.decode(EventJSON.make(
            bird: "app", topic: "app.bird.paused", ts: world.now.formatted(.iso8601), data: #"{"bird": "owl"}"#))
        world.flock.apply(paused)
        #expect(world.idleBirds == Set(Bird.allCases).subtracting([.owl]))
    }

    @Test func pointsMeasureStraightLineDistance() {
        #expect(PetPoint(x: 0, y: 0).distance(to: PetPoint(x: 3, y: 4)) == 5)
    }

    @Test func dockIconsArePreferredOverEverything() {
        #expect(Perch.Kind.allCases.sorted() == [.dockIcon, .dockEdge, .windowTop, .menuBar])
    }
}
