import Foundation
import Testing
@testable import NestKit

struct PetDirectorTests {
    struct Tick: Equatable {
        let offset: Double
        let plan: PetPlan
        let intents: [Bird: PetIntent]
        let idle: Set<Bird>
    }

    static let xcode = "com.apple.dt.Xcode"
    static let zoom = "us.zoom.xos"
    static let safari = "com.apple.Safari"

    /// Two hours from 10:00, a tick every half second, with the pointer still at (300, 400):
    /// input with Xcode in front until 62 min (Crow busy 30 to 40), no input until 70, Zoom until 75, then Safari.
    static func session(seed: UInt64) -> [Tick] {
        var director = PetDirector(seed: seed)
        var flock = FlockState()
        let perches = PetWorld.fixturePerches + [
            Perch(kind: .dockIcon, point: PetPoint(x: 700, y: 0), app: xcode),
            Perch(kind: .dockIcon, point: PetPoint(x: 800, y: 0), app: zoom),
            Perch(kind: .dockIcon, point: PetPoint(x: 900, y: 0), app: safari),
        ]
        var ticks: [Tick] = []
        for step in 0...(120 * 60 * 2) {
            let offset = Double(step) / 2
            let minute = offset / 60
            let now = PetWorld.fixtureStart + offset
            if (30...40).contains(minute), offset.truncatingRemainder(dividingBy: 60) == 0 {
                flock.apply(try! EventJSON.decode(EventJSON.make(bird: "crow", topic: "crow.friction.seen", ts: now.formatted(.iso8601))))
            }
            let quiet = (62..<70).contains(minute) ? offset - 62 * 60 : offset.truncatingRemainder(dividingBy: 1)
            let front = minute < 70 ? xcode : minute < 75 ? zoom : safari
            let world = PetWorld(now: now, flock: flock, secondsSinceInput: quiet, frontApp: front, hour: 10 + Int(minute) / 60,
                                 pointer: PetPoint(x: 300, y: 400), pointerSpeed: 0, perches: perches,
                                 homes: PetWorld.fixtureHomes, hideCauses: [])
            let intents = director.tick(world)
            ticks.append(Tick(offset: offset, plan: director.plan, intents: intents, idle: world.idleBirds))
        }
        return ticks
    }

    @Test func aTwoHourSessionKeepsEveryRule() {
        let ticks = Self.session(seed: 42)

        for tick in ticks {
            #expect(tick.plan.out.isSubset(of: tick.idle))
            #expect(Set(tick.intents.keys) == Set(Bird.allCases))
            if (30 * 60...50 * 60).contains(tick.offset) {
                #expect(!tick.plan.out.contains(.crow))
            }
            let perched = tick.intents.filter { tick.plan.out.contains($0.key) && $0.value.activity == .perched }.map(\.value.target)
            for (i, a) in perched.enumerated() {
                for b in perched[(i + 1)...] {
                    #expect(a.distance(to: b) >= 32)
                }
            }
        }

        let firstVisit = ticks.first { $0.plan.mode == .visitor && !$0.plan.out.isEmpty }
        #expect(firstVisit.map { (10 * 60...20 * 60).contains($0.offset) } == true)
        #expect(firstVisit?.plan.out == [.swift])

        let firstBreak = ticks.first { $0.plan.mode == .breakBuddy }
        #expect(firstBreak.map { (50 * 60..<51 * 60).contains($0.offset) } == true)

        let firstLively = ticks.first { $0.plan.mode == .lively }
        #expect(firstLively?.offset == Double(65 * 60))

        guard let zoom = ticks.firstIndex(where: { $0.offset == 70 * 60 }) else {
            Issue.record("No tick at 70 min")
            return
        }
        #expect(ticks[zoom].plan.mode == .hidden)
        let wereOut = ticks[zoom - 1].intents.filter { $0.value.activity != .home }.map(\.key)
        #expect(!wereOut.isEmpty)
        for bird in wereOut {
            #expect(ticks[zoom].intents[bird]?.activity == .flyingHome)
            #expect(ticks[zoom].intents[bird]?.travel == 0.42)
        }
        #expect(ticks[zoom + 1].intents.values.allSatisfy { $0.activity == .home })
        for tick in ticks where (70 * 60..<75 * 60).contains(tick.offset) {
            #expect(tick.plan.out.isEmpty)
        }
    }

    @Test func theSameSeedReplaysTheSameSession() {
        #expect(Self.session(seed: 42) == Self.session(seed: 42))
    }

    @Test func differentSeedsDiffer() {
        #expect(Self.session(seed: 42) != Self.session(seed: 43))
    }

    @Test func theFirstPlanIsAnEmptyVisitor() {
        #expect(PetDirector(seed: 1).plan == PetPlan(mode: .visitor, out: [], favoured: nil, hideCauses: []))
    }
}
