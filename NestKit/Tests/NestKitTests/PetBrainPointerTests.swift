import Foundation
import Testing
@testable import NestKit

struct PetBrainPointerTests {
    static let start = PetWorld.fixtureStart
    static let seat = PetPoint(x: 300, y: 0)
    static let far = PetPoint(x: 2000, y: 2000)

    /// One Dock icon at (300, 0) and a row of menu bar perches far away.
    static let perches = [Perch(kind: .dockIcon, point: seat)]
        + (0..<6).map { Perch(kind: .menuBar, point: PetPoint(x: Double($0) * 200, y: 900)) }

    /// A brain with `bird` perched at (300, 0) 1.5 s after the start, the pointer still and far away since the start.
    struct Scene {
        let bird: Bird
        var brain = PetBrain(settings: PetSettings())
        var rng = PetRandom(seed: 1)
        var plan: PetPlan

        init(_ bird: Bird) {
            self.bird = bird
            plan = PetPlan(mode: .visitor, out: [bird], favoured: nil, hideCauses: [])
            _ = tick(at: 0)
            let landed = tick(at: 1.5)
            precondition(landed.activity == .perched && landed.target == PetBrainPointerTests.seat)
        }

        mutating func tick(at offset: Double, pointer: PetPoint = PetBrainPointerTests.far, speed: Double = 0,
                           busy: Set<Bird> = []) -> PetIntent {
            let world = PetWorld.fixture(now: PetBrainPointerTests.start + offset, pointer: pointer, pointerSpeed: speed,
                                         perches: PetBrainPointerTests.perches, busy: busy)
            return brain.intents(plan: busy.contains(bird) ? PetPlan(mode: .visitor, out: [], favoured: nil, hideCauses: []) : plan,
                                 world: world, using: &rng)[bird]!
        }
    }

    @Test func aFastPointerMakesSwiftFlee() {
        var scene = Scene(.swift)
        let pointer = PetPoint(x: 300, y: 100)
        let fled = scene.tick(at: 2, pointer: pointer, speed: 500)
        #expect(fled.activity == .fleeing)
        #expect(fled.reaction == .dartAway)
        #expect(fled.travel == 1.5)
        #expect(fled.target.distance(to: pointer) > 200)
    }

    @Test func theSameRushLeavesOwlPerched() {
        var scene = Scene(.owl)
        let owl = scene.tick(at: 2, pointer: PetPoint(x: 300, y: 100), speed: 2000)
        #expect(owl.activity == .perched)
        #expect(owl.target == Self.seat)
    }

    @Test func swiftCirclesBackAfterFleeing() {
        var scene = Scene(.swift)
        _ = scene.tick(at: 2, pointer: PetPoint(x: 300, y: 100), speed: 500)
        #expect(scene.tick(at: 3.5).activity == .perched)
        let back = scene.tick(at: 4)
        #expect(back.activity == .flyingOut)
        #expect(back.target == Self.seat)
    }

    @Test func peacockDoesNotComeBackAfterFleeing() {
        var scene = Scene(.peacock)
        let fled = scene.tick(at: 2, pointer: PetPoint(x: 300, y: 50), speed: 800)
        for offset in stride(from: 2.5, through: 9, by: 0.5) {
            #expect(scene.tick(at: offset).target != Self.seat)
        }
        #expect(fled.activity == .fleeing)
    }

    @Test(arguments: [(Bird.wren, PetReaction.hopCloser), (.swift, .tiltHead), (.crow, .tiltHead), (.owl, .blink),
                      (.magpie, .stealSparkle), (.peacock, .fanTail)])
    func hoverGivesEachBirdItsReaction(_ bird: Bird, _ reaction: PetReaction) {
        var scene = Scene(bird)
        let hovered = scene.tick(at: 1.5, pointer: PetPoint(x: 310, y: 0), speed: 0)
        #expect(hovered.reaction == reaction)
        #expect(hovered.activity == .perched)
    }

    @Test func rushingPeacockHuffs() {
        var scene = Scene(.peacock)
        let peacock = scene.tick(at: 2, pointer: PetPoint(x: 300, y: 50), speed: 800)
        #expect(peacock.activity == .fleeing)
        #expect(peacock.reaction == .huff)
    }

    @Test func wrenSitsOnAStillPointerAfterFourSeconds() {
        var scene = Scene(.wren)
        let pointer = PetPoint(x: 310, y: 0)
        let early = scene.tick(at: 3.9, pointer: pointer)
        #expect(early.reaction == .hopCloser)
        #expect(early.target == Self.seat)
        let sitting = scene.tick(at: 4, pointer: pointer)
        #expect(sitting.activity == .perched)
        #expect(sitting.target == pointer)
        #expect(sitting.reaction == .sitOnPointer)
    }

    @Test func aMovingPointerResetsWrensPatience() {
        var scene = Scene(.wren)
        let pointer = PetPoint(x: 310, y: 0)
        _ = scene.tick(at: 1.5, pointer: pointer, speed: 100)
        #expect(scene.tick(at: 4, pointer: pointer).reaction == .hopCloser)
        #expect(scene.tick(at: 5.4, pointer: pointer).reaction == .hopCloser)
        #expect(scene.tick(at: 5.5, pointer: pointer).reaction == .sitOnPointer)
    }

    @Test func wrenGoesBackToItsPerchWhenThePointerLeaves() {
        var scene = Scene(.wren)
        let pointer = PetPoint(x: 310, y: 0)
        _ = scene.tick(at: 4, pointer: pointer)
        let after = scene.tick(at: 4.5)
        #expect(after.target == Self.seat)
        #expect(after.reaction == nil)
    }

    @Test func magpieHopsTowardAStillPointer() {
        var scene = Scene(.magpie)
        let pointer = PetPoint(x: 300, y: 150)
        let magpie = scene.tick(at: 2, pointer: pointer)
        #expect(magpie.activity == .hopping)
        #expect(magpie.reaction == .hopCloser)
        #expect(abs(magpie.target.distance(to: pointer) - 28) < 0.001)
        #expect(magpie.target.distance(to: Self.seat) < pointer.distance(to: Self.seat))
    }

    @Test func magpieWaitsUntilThePointerHasBeenStillForTwoSeconds() {
        var scene = Scene(.magpie)
        _ = scene.tick(at: 1.9, pointer: PetPoint(x: 300, y: 150), speed: 100)
        #expect(scene.tick(at: 3.8, pointer: PetPoint(x: 300, y: 150)).reaction == nil)
    }

    @Test func crowFollowsAMovingPointer() {
        var scene = Scene(.crow)
        let pointer = PetPoint(x: 300, y: 150)
        let crow = scene.tick(at: 2, pointer: pointer, speed: 200)
        #expect(crow.activity == .following)
        #expect(abs(crow.target.distance(to: pointer) - 120) < 0.001)
        #expect(crow.target.distance(to: Self.seat) < pointer.distance(to: Self.seat))
    }

    @Test func owlWatchesFromAfar() {
        var scene = Scene(.owl)
        let owl = scene.tick(at: 2, pointer: PetPoint(x: 300, y: 150))
        #expect(owl.reaction == .watch)
        #expect(owl.activity == .perched)
    }

    @Test(arguments: Bird.allCases)
    func farPointersChangeNothing(_ bird: Bird) {
        var scene = Scene(bird)
        for speed in [0.0, 200, 5000] {
            let intent = scene.tick(at: 2, pointer: PetPoint(x: 300, y: 500), speed: speed)
            #expect(intent.reaction == nil)
            #expect(intent.activity == .perched)
            #expect(intent.target == Self.seat)
        }
    }

    @Test func busyBeatsEveryPointerReaction() {
        var scene = Scene(.wren)
        let pointer = PetPoint(x: 310, y: 0)
        #expect(scene.tick(at: 4, pointer: pointer).reaction == .sitOnPointer)
        let busy = scene.tick(at: 4.5, pointer: pointer, busy: [.wren])
        #expect(busy.activity == .flyingHome)
        #expect(busy.travel == 0.42)
        #expect(busy.reaction == nil)
        #expect(scene.tick(at: 4.92, pointer: pointer, busy: [.wren]).activity == .home)
    }

    @Test func busyBeatsFleeing() {
        var scene = Scene(.swift)
        _ = scene.tick(at: 2, pointer: PetPoint(x: 300, y: 100), speed: 500)
        let busy = scene.tick(at: 2.5, busy: [.swift])
        #expect(busy.activity == .flyingHome)
        #expect(busy.travel == 0.42)
        #expect(busy.reaction == nil)
    }
}
