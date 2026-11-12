import Foundation
import Testing
@testable import NestKit

struct PetBrainMovementTests {
    static let start = PetWorld.fixtureStart
    static let xcode = "com.apple.dt.Xcode"
    static let safari = "com.apple.Safari"

    static func plan(_ mode: PetMode = .visitor, out: Set<Bird> = [], favoured: Bird? = nil) -> PetPlan {
        PetPlan(mode: mode, out: out, favoured: favoured, hideCauses: mode == .hidden ? [.hotkeyOff] : [])
    }

    /// Ticks every half second from `from` to `to` seconds after the start with the same plan, returning the last intents.
    @discardableResult
    static func run(
        _ brain: inout PetBrain,
        _ rng: inout PetRandom,
        _ plan: PetPlan,
        from: Double = 0,
        to: Double,
        world: (Date) -> PetWorld = { PetWorld.fixture(now: $0) }
    ) -> [Bird: PetIntent] {
        var last: [Bird: PetIntent] = [:]
        for offset in stride(from: from, through: to, by: 0.5) {
            last = brain.intents(plan: plan, world: world(start + offset), using: &rng)
        }
        return last
    }

    @Test func aPlannedBirdFliesOutToADockIcon() {
        var brain = PetBrain(settings: PetSettings())
        var rng = PetRandom(seed: 1)
        let intents = brain.intents(plan: Self.plan(out: [.wren]), world: .fixture(), using: &rng)
        let wren = intents[.wren]
        #expect(wren?.activity == .flyingOut)
        #expect(wren?.shape == .flight)
        #expect(wren?.travel == 1.5)
        #expect(PetWorld.fixturePerches.map(\.point).contains { $0 == wren?.target })
        for bird in Bird.allCases where bird != .wren {
            #expect(intents[bird]?.activity == .home)
            #expect(intents[bird]?.target == PetWorld.fixtureHomes[bird])
        }
    }

    @Test func itPerchesWhenTheFlightEnds() {
        var brain = PetBrain(settings: PetSettings())
        var rng = PetRandom(seed: 1)
        let plan = Self.plan(out: [.wren])
        let out = brain.intents(plan: plan, world: .fixture(), using: &rng)[.wren]
        #expect(brain.intents(plan: plan, world: .fixture(now: Self.start + 1.4), using: &rng)[.wren]?.activity == .flyingOut)
        let landed = brain.intents(plan: plan, world: .fixture(now: Self.start + 1.5), using: &rng)[.wren]
        #expect(landed?.activity == .perched)
        #expect(landed?.shape == .glyph)
        #expect(landed?.target == out?.target)
    }

    @Test func aBirdTurningActiveHeadsHomeOnTheNextTick() {
        var brain = PetBrain(settings: PetSettings())
        var rng = PetRandom(seed: 1)
        Self.run(&brain, &rng, Self.plan(out: [.wren]), to: 5)
        let busy = brain.intents(plan: Self.plan(), world: .fixture(now: Self.start + 5.5, busy: [.wren]), using: &rng)[.wren]
        #expect(busy?.activity == .flyingHome)
        #expect(busy?.travel == PetSettings.goHome)
        #expect(busy?.target == PetWorld.fixtureHomes[.wren])
    }

    @Test func aBirdFlyingHomeThatTurnsActiveHurries() {
        var brain = PetBrain(settings: PetSettings())
        var rng = PetRandom(seed: 1)
        Self.run(&brain, &rng, Self.plan(out: [.wren]), to: 5)
        #expect(brain.intents(plan: Self.plan(), world: .fixture(now: Self.start + 5.5), using: &rng)[.wren]?.travel == 1.5)
        let busy = brain.intents(plan: Self.plan(), world: .fixture(now: Self.start + 5.6, busy: [.wren]), using: &rng)[.wren]
        #expect(busy?.travel == PetSettings.goHome)
        #expect(brain.intents(plan: Self.plan(), world: .fixture(now: Self.start + 6.02, busy: [.wren]), using: &rng)[.wren]?.activity == .home)
    }

    @Test func hiddenSendsEveryBirdHomeWithin420ms() {
        var brain = PetBrain(settings: PetSettings())
        var rng = PetRandom(seed: 1)
        let three: Set<Bird> = [.wren, .crow, .peacock]
        Self.run(&brain, &rng, Self.plan(.breakBuddy, out: three), to: 5)
        let hidden = brain.intents(plan: Self.plan(.hidden), world: .fixture(now: Self.start + 5.5), using: &rng)
        for bird in three {
            #expect(hidden[bird]?.activity == .flyingHome)
            #expect(hidden[bird]?.travel == 0.42)
        }
        let home = brain.intents(plan: Self.plan(.hidden), world: .fixture(now: Self.start + 5.92), using: &rng)
        #expect(Bird.allCases.allSatisfy { home[$0]?.activity == .home })
    }

    @Test func leavingLivelyDriftsHomeInTwoSeconds() {
        var brain = PetBrain(settings: PetSettings())
        var rng = PetRandom(seed: 1)
        Self.run(&brain, &rng, Self.plan(.lively, out: [.wren, .owl]), to: 5)
        let back = brain.intents(plan: Self.plan(), world: .fixture(now: Self.start + 5.5), using: &rng)
        #expect(back[.wren]?.activity == .flyingHome)
        #expect(back[.wren]?.travel == 2)
        #expect(back[.owl]?.travel == 2)
    }

    @Test func theFavouredBirdPerchesOnTheFrontApp() {
        let icon = Perch(kind: .dockIcon, point: PetPoint(x: 700, y: 0), app: Self.xcode)
        let window = Perch(kind: .windowTop, point: PetPoint(x: 800, y: 300), app: Self.xcode)
        for seed in UInt64(0)..<10 {
            var brain = PetBrain(settings: PetSettings())
            var rng = PetRandom(seed: seed)
            let world = PetWorld.fixture(frontApp: Self.xcode, perches: PetWorld.fixturePerches + [window, icon])
            #expect(brain.intents(plan: Self.plan(out: [.swift], favoured: .swift), world: world, using: &rng)[.swift]?.target == icon.point)
        }
    }

    @Test func aFavouredBirdUsesTheAppsWindowWhenItHasNoDockIcon() {
        let window = Perch(kind: .windowTop, point: PetPoint(x: 800, y: 300), app: Self.xcode)
        var brain = PetBrain(settings: PetSettings())
        var rng = PetRandom(seed: 1)
        let world = PetWorld.fixture(frontApp: Self.xcode, perches: PetWorld.fixturePerches + [window])
        #expect(brain.intents(plan: Self.plan(out: [.swift], favoured: .swift), world: world, using: &rng)[.swift]?.target == window.point)
    }

    @Test func breakBuddiesPerchNearThePointer() {
        var brain = PetBrain(settings: PetSettings())
        var rng = PetRandom(seed: 1)
        let world = PetWorld.fixture(pointer: PetPoint(x: 420, y: 50))
        #expect(brain.intents(plan: Self.plan(.breakBuddy, out: [.wren]), world: world, using: &rng)[.wren]?.target == PetPoint(x: 400, y: 0))
    }

    @Test func twoBirdsNeverShareAPerch() {
        let close = (0..<6).map { Perch(kind: .dockIcon, point: PetPoint(x: Double($0) * 10, y: 0)) }
        for seed in UInt64(0)..<10 {
            var brain = PetBrain(settings: PetSettings())
            var rng = PetRandom(seed: seed)
            for offset in stride(from: 0.0, through: 120, by: 0.5) {
                let world = PetWorld.fixture(now: Self.start + offset, perches: close)
                let intents = brain.intents(plan: Self.plan(.lively, out: Set(Bird.allCases)), world: world, using: &rng)
                let perched = intents.values.filter { $0.activity == .perched }.map(\.target)
                for (i, a) in perched.enumerated() {
                    for b in perched[(i + 1)...] {
                        #expect(a.distance(to: b) >= 32)
                    }
                }
            }
        }
    }

    @Test func extraBirdsStayHomeWhenPerchesRunOut() {
        let one = [Perch(kind: .dockIcon, point: PetPoint(x: 0, y: 0))]
        var brain = PetBrain(settings: PetSettings())
        var rng = PetRandom(seed: 1)
        let intents = brain.intents(plan: Self.plan(.lively, out: Set(Bird.allCases)), world: .fixture(perches: one), using: &rng)
        #expect(intents.values.filter { $0.activity == .flyingOut }.count == 1)
        #expect(intents.values.filter { $0.activity == .home }.count == 5)
    }

    @Test func withNoPerchesBirdsStayHome() {
        var brain = PetBrain(settings: PetSettings())
        var rng = PetRandom(seed: 1)
        for offset in stride(from: 0.0, to: 50, by: 0.5) {
            let intents = brain.intents(plan: Self.plan(.lively, out: Set(Bird.allCases)),
                                        world: .fixture(now: Self.start + offset, perches: []), using: &rng)
            #expect(Bird.allCases.allSatisfy { intents[$0]?.activity == .home })
        }
    }

    @Test func dockIconsArePreferredOverTheMenuBar() {
        let bar = (0..<3).map { Perch(kind: .menuBar, point: PetPoint(x: Double($0) * 100, y: 900)) }
        let icon = Perch(kind: .dockIcon, point: PetPoint(x: 500, y: 0))
        let edge = Perch(kind: .dockEdge, point: PetPoint(x: 600, y: 0))
        for seed in UInt64(0)..<10 {
            var brain = PetBrain(settings: PetSettings())
            var rng = PetRandom(seed: seed)
            let world = PetWorld.fixture(perches: bar + [edge, icon])
            #expect(brain.intents(plan: Self.plan(out: [.wren]), world: world, using: &rng)[.wren]?.target == icon.point)
        }
    }

    @Test func crowFliesToTheAppJustOpened() {
        var brain = PetBrain(settings: PetSettings())
        var rng = PetRandom(seed: 1)
        Self.run(&brain, &rng, Self.plan(out: [.crow]), to: 2)
        let icon = Perch(kind: .dockIcon, point: PetPoint(x: 900, y: 0), app: Self.safari)
        let world = PetWorld.fixture(now: Self.start + 2.5, frontApp: Self.safari, perches: PetWorld.fixturePerches + [icon])
        let crow = brain.intents(plan: Self.plan(out: [.crow]), world: world, using: &rng)[.crow]
        #expect(crow?.activity == .flyingOut)
        #expect(crow?.target == icon.point)
    }

    @Test func lessCuriousBirdsIgnoreTheAppJustOpened() {
        var brain = PetBrain(settings: PetSettings())
        var rng = PetRandom(seed: 1)
        let before = Self.run(&brain, &rng, Self.plan(out: [.owl]), to: 2)[.owl]
        let icon = Perch(kind: .dockIcon, point: PetPoint(x: 900, y: 0), app: Self.safari)
        let world = PetWorld.fixture(now: Self.start + 2.5, frontApp: Self.safari, perches: PetWorld.fixturePerches + [icon])
        #expect(brain.intents(plan: Self.plan(out: [.owl]), world: world, using: &rng)[.owl]?.target == before?.target)
    }

    @Test func magpieCarriesAGlintHome() {
        var brain = PetBrain(settings: PetSettings())
        var rng = PetRandom(seed: 1)
        Self.run(&brain, &rng, Self.plan(out: [.magpie, .wren]), to: 3)
        let leaving = brain.intents(plan: Self.plan(), world: .fixture(now: Self.start + 3.5), using: &rng)
        #expect(leaving[.magpie]?.activity == .flyingHome)
        #expect(leaving[.magpie]?.reaction == .carryGlint)
        #expect(leaving[.wren]?.reaction == nil)
    }

    @Test func aBirdWithNoHomeNeverComesOut() {
        var brain = PetBrain(settings: PetSettings())
        var rng = PetRandom(seed: 1)
        var homes = PetWorld.fixtureHomes
        homes[.owl] = nil
        let intents = Self.run(&brain, &rng, Self.plan(.lively, out: Set(Bird.allCases)), to: 10) { PetWorld.fixture(now: $0, homes: homes) }
        #expect(intents[.owl]?.activity == .home)
    }

    @Test func visitorsDoTheirHabit() {
        var brain = PetBrain(settings: PetSettings())
        var rng = PetRandom(seed: 1)
        var seen: Set<PetActivity> = []
        for offset in stride(from: 0.0, through: 600, by: 0.5) {
            seen.insert(brain.intents(plan: Self.plan(out: [.peacock]), world: .fixture(now: Self.start + offset), using: &rng)[.peacock]!.activity)
        }
        #expect(seen.contains(.preening))
        #expect(!seen.contains(.looping))
        #expect(!seen.contains(.chasing))
    }

    @Test func livelyBirdsLoopAndChase() {
        var brain = PetBrain(settings: PetSettings())
        var rng = PetRandom(seed: 1)
        var seen: Set<PetActivity> = []
        for offset in stride(from: 0.0, through: 600, by: 0.5) {
            let intents = brain.intents(plan: Self.plan(.lively, out: Set(Bird.allCases)), world: .fixture(now: Self.start + offset), using: &rng)
            seen.formUnion(intents.values.map(\.activity))
        }
        #expect(seen.isSuperset(of: [.looping, .chasing, .perched, .flyingOut]))
    }

    @Test func everyBirdHasAnIntentEveryTick() {
        var brain = PetBrain(settings: PetSettings())
        var rng = PetRandom(seed: 5)
        var script = PetRandom(seed: 6)
        let modes: [PetMode] = [.visitor, .breakBuddy, .lively, .hidden]
        for offset in stride(from: 0.0, through: 300, by: 0.5) {
            let mode = modes.randomElement(using: &script)!
            let out = mode == .hidden ? [] : Set(Bird.allCases.filter { _ in Bool.random(using: &script) })
            let intents = brain.intents(plan: Self.plan(mode, out: out), world: .fixture(now: Self.start + offset), using: &rng)
            #expect(Set(intents.keys) == Set(Bird.allCases))
        }
    }
}
