import Foundation
import Testing
@testable import NestKit

struct PetSchedulerTests {
    let start = PetWorld.fixtureStart
    let settings = PetSettings()

    /// Ticks once a second from `from` to `to` seconds after the start, returning each tick's plan.
    static func run(
        _ scheduler: inout PetScheduler,
        _ rng: inout PetRandom,
        from: Int = 0,
        to: Int,
        streak: TimeInterval = 0,
        world: (Date) -> PetWorld = { PetWorld.fixture(now: $0) }
    ) -> [(offset: Int, plan: PetPlan)] {
        (from...to).map { offset in
            let now = PetWorld.fixtureStart + TimeInterval(offset)
            return (offset, scheduler.plan(world(now), streak: streak, using: &rng))
        }
    }

    /// Ticks once a second until a bird comes out, returning that offset and plan.
    static func untilVisit(_ scheduler: inout PetScheduler, _ rng: inout PetRandom, frontApp: String) -> (offset: Int, plan: PetPlan)? {
        for offset in 0...1300 {
            let plan = scheduler.plan(.fixture(now: PetWorld.fixtureStart + TimeInterval(offset), frontApp: frontApp), streak: 0, using: &rng)
            if !plan.out.isEmpty {
                return (offset, plan)
            }
        }
        return nil
    }

    @Test func threeMinutesWithoutInputIsLivelyWithEveryIdleBird() {
        var scheduler = PetScheduler(settings: settings)
        var rng = PetRandom(seed: 1)
        let plan = scheduler.plan(.fixture(secondsSinceInput: 180, busy: [.crow]), streak: 0, using: &rng)
        #expect(plan.mode == .lively)
        #expect(plan.out == Set(Bird.allCases).subtracting([.crow]))
    }

    @Test func twoMinutesFiftyNineIsNotLively() {
        var scheduler = PetScheduler(settings: settings)
        var rng = PetRandom(seed: 1)
        #expect(scheduler.plan(.fixture(secondsSinceInput: 179), streak: 0, using: &rng).mode != .lively)
    }

    @Test func fiftyMinutesOfWorkBringsTwoOrThreeBirds() {
        for seed in UInt64(0)..<20 {
            var scheduler = PetScheduler(settings: settings)
            var rng = PetRandom(seed: seed)
            let plan = scheduler.plan(.fixture(), streak: 3000, using: &rng)
            #expect(plan.mode == .breakBuddy)
            #expect((2...3).contains(plan.out.count))
        }
    }

    @Test func fortyNineMinutesIsNoBreak() {
        var scheduler = PetScheduler(settings: settings)
        var rng = PetRandom(seed: 1)
        #expect(scheduler.plan(.fixture(), streak: 2999, using: &rng).mode != .breakBuddy)
    }

    @Test func theBreakLastsThreeMinutesThenCoolsDownTwentyMinutes() {
        var scheduler = PetScheduler(settings: settings)
        var rng = PetRandom(seed: 1)
        func mode(at offset: TimeInterval) -> PetMode {
            scheduler.plan(.fixture(now: start + offset), streak: 3000 + offset, using: &rng).mode
        }
        #expect(mode(at: 0) == .breakBuddy)
        #expect(mode(at: 179) == .breakBuddy)
        #expect(mode(at: 180) != .breakBuddy)
        #expect(mode(at: 180 + 1199) != .breakBuddy)
        #expect(mode(at: 180 + 1200) == .breakBuddy)
    }

    @Test func aBreakTakesNoMoreBirdsThanAreIdle() {
        var scheduler = PetScheduler(settings: settings)
        var rng = PetRandom(seed: 1)
        let plan = scheduler.plan(.fixture(busy: [.wren, .swift, .crow, .owl, .magpie]), streak: 3000, using: &rng)
        #expect(plan.mode == .breakBuddy)
        #expect(plan.out == [.peacock])
    }

    @Test func theFirstVisitComesBetweenTenAndTwentyMinutes() {
        for seed in UInt64(0)..<10 {
            var scheduler = PetScheduler(settings: settings)
            var rng = PetRandom(seed: seed)
            let ticks = Self.run(&scheduler, &rng, to: 1300)
            let first = ticks.first { !$0.plan.out.isEmpty }
            #expect(first.map { (600...1200).contains($0.offset) } == true)
            #expect(first?.plan.out.count == 1)
            #expect(first?.plan.mode == .visitor)
        }
    }

    @Test func aVisitLastsOneToFourMinutes() {
        for seed in UInt64(0)..<10 {
            var scheduler = PetScheduler(settings: settings)
            var rng = PetRandom(seed: seed)
            let ticks = Self.run(&scheduler, &rng, to: 1600)
            guard let first = ticks.firstIndex(where: { !$0.plan.out.isEmpty }),
                  let end = ticks[first...].firstIndex(where: { $0.plan.out.isEmpty }) else {
                Issue.record("No complete visit with seed \(seed)")
                continue
            }
            #expect((60...241).contains(ticks[end].offset - ticks[first].offset))
            #expect(Set(ticks[first..<end].map(\.plan.out)).count == 1)
        }
    }

    @Test(arguments: HideCause.allCases)
    func anyHideCauseEmptiesTheSky(_ cause: HideCause) {
        var scheduler = PetScheduler(settings: settings)
        var rng = PetRandom(seed: 1)
        #expect(scheduler.plan(.fixture(), streak: 3000, using: &rng).mode == .breakBuddy)
        let midBreak = scheduler.plan(.fixture(now: start + 1, hideCauses: [cause]), streak: 3001, using: &rng)
        #expect(midBreak.mode == .hidden)
        #expect(midBreak.out.isEmpty)
        #expect(midBreak.hideCauses.contains(cause))
        let lively = scheduler.plan(.fixture(now: start + 2, secondsSinceInput: 600, hideCauses: [cause]), streak: 0, using: &rng)
        #expect(lively.mode == .hidden)
        #expect(lively.out.isEmpty)
    }

    @Test func hidingEndsTheBreakInProgress() {
        var scheduler = PetScheduler(settings: settings)
        var rng = PetRandom(seed: 1)
        _ = scheduler.plan(.fixture(), streak: 3000, using: &rng)
        _ = scheduler.plan(.fixture(now: start + 1, hideCauses: [.fullScreen]), streak: 3001, using: &rng)
        #expect(scheduler.plan(.fixture(now: start + 2), streak: 3002, using: &rng).mode != .breakBuddy)
    }

    @Test func zoomInFrontHides() {
        var scheduler = PetScheduler(settings: settings)
        var rng = PetRandom(seed: 1)
        let plan = scheduler.plan(.fixture(frontApp: "us.zoom.xos"), streak: 0, using: &rng)
        #expect(plan.mode == .hidden)
        #expect(plan.hideCauses == [.meetingApp])
    }

    @Test func hiddenBeatsLivelyBeatsBreakBeatsVisitor() {
        func mode(_ world: PetWorld, streak: TimeInterval) -> PetMode {
            var scheduler = PetScheduler(settings: settings)
            var rng = PetRandom(seed: 1)
            return scheduler.plan(world, streak: streak, using: &rng).mode
        }
        #expect(mode(.fixture(secondsSinceInput: 200, hideCauses: [.hotkeyOff]), streak: 3000) == .hidden)
        #expect(mode(.fixture(secondsSinceInput: 200), streak: 3000) == .lively)
        #expect(mode(.fixture(), streak: 3000) == .breakBuddy)
        #expect(mode(.fixture(), streak: 0) == .visitor)
    }

    @Test func afterHidingTheNextVisitWaitsAFullGap() {
        var scheduler = PetScheduler(settings: settings)
        var rng = PetRandom(seed: 1)
        let hidden = Self.run(&scheduler, &rng, to: 1300) { PetWorld.fixture(now: $0, hideCauses: [.hotkeyOff]) }
        #expect(hidden.allSatisfy { $0.plan.mode == .hidden })
        let after = Self.run(&scheduler, &rng, from: 1301, to: 1301 + 599)
        #expect(after.allSatisfy { $0.plan.out.isEmpty })
    }

    @Test func withXcodeInFrontSwiftIsFavoured() {
        #expect(PetScheduler.favoured(in: .fixture(frontApp: "com.apple.dt.Xcode"), settings: settings) == .swift)
    }

    @Test func eachBirdIsFavouredByItsOwnApps() {
        for bird in Bird.allCases {
            for app in BirdQuirks.of(bird).apps {
                #expect(PetScheduler.favoured(in: .fixture(frontApp: app), settings: settings) == bird)
            }
        }
    }

    @Test func afterElevenOwlBeatsAppPreferences() {
        let xcode = "com.apple.dt.Xcode"
        #expect(PetScheduler.favoured(in: .fixture(frontApp: xcode, hour: 23), settings: settings) == .owl)
        #expect(PetScheduler.favoured(in: .fixture(frontApp: xcode, hour: 4), settings: settings) == .owl)
        #expect(PetScheduler.favoured(in: .fixture(frontApp: xcode, hour: 5), settings: settings) == .swift)
        #expect(PetScheduler.favoured(in: .fixture(frontApp: xcode, hour: 22), settings: settings) == .swift)
    }

    @Test func aBusyFavouriteIsSkipped() {
        #expect(PetScheduler.favoured(in: .fixture(frontApp: "com.apple.dt.Xcode", busy: [.swift]), settings: settings) != .swift)
        #expect(PetScheduler.favoured(in: .fixture(frontApp: "com.apple.dt.Xcode", hour: 23, busy: [.owl]), settings: settings) == .swift)
    }

    @Test func noFrontAppFavoursNobody() {
        #expect(PetScheduler.favoured(in: .fixture(), settings: settings) == nil)
    }

    @Test func theFavouredBirdIsTheVisitor() {
        var scheduler = PetScheduler(settings: settings)
        var rng = PetRandom(seed: 1)
        let ticks = Self.run(&scheduler, &rng, to: 1300) { PetWorld.fixture(now: $0, frontApp: "com.apple.Notes") }
        let first = ticks.first { !$0.plan.out.isEmpty }
        #expect(first?.plan.out == [.magpie])
        #expect(first?.plan.favoured == .magpie)
    }

    @Test func outIsAlwaysIdle() {
        var scheduler = PetScheduler(settings: settings)
        var rng = PetRandom(seed: 3)
        var worldRandom = PetRandom(seed: 99)
        for offset in 0..<2000 {
            let busy = Set(Bird.allCases.filter { _ in Bool.random(using: &worldRandom) })
            let quiet: TimeInterval = Int.random(in: 0..<10, using: &worldRandom) == 0 ? 200 : 0
            let world = PetWorld.fixture(now: start + TimeInterval(offset), secondsSinceInput: quiet, busy: busy)
            let plan = scheduler.plan(world, streak: TimeInterval(offset * 3), using: &rng)
            #expect(plan.out.isSubset(of: world.idleBirds))
        }
    }

    @Test func switchingAppsMidVisitKeepsTheVisitor() {
        var scheduler = PetScheduler(settings: settings)
        var rng = PetRandom(seed: 1)
        guard let first = Self.untilVisit(&scheduler, &rng, frontApp: "com.apple.dt.Xcode") else {
            Issue.record("No visit")
            return
        }
        #expect(first.plan.out == [.swift])
        let next = scheduler.plan(.fixture(now: start + TimeInterval(first.offset + 1), frontApp: "com.apple.Safari"), streak: 0, using: &rng)
        #expect(next.out == [.swift])
        #expect(next.favoured == .crow)
    }

    @Test func aVisitorThatGetsWorkGoesHome() {
        var scheduler = PetScheduler(settings: settings)
        var rng = PetRandom(seed: 1)
        guard let first = Self.untilVisit(&scheduler, &rng, frontApp: "com.apple.dt.Xcode") else {
            Issue.record("No visit")
            return
        }
        let next = scheduler.plan(.fixture(now: start + TimeInterval(first.offset + 1), frontApp: "com.apple.dt.Xcode", busy: [.swift]),
                                  streak: 0, using: &rng)
        #expect(next.out.isEmpty)
    }

    @Test func aClockJumpDoesNotReleaseABacklogOfVisits() {
        for seed in UInt64(0)..<10 {
            var scheduler = PetScheduler(settings: settings)
            var rng = PetRandom(seed: seed)
            _ = Self.run(&scheduler, &rng, to: 10)
            let woke = scheduler.plan(.fixture(now: start + 6 * 3600), streak: 0, using: &rng)
            #expect(woke.out.isEmpty)
            let after = Self.run(&scheduler, &rng, from: 6 * 3600 + 1, to: 6 * 3600 + 599)
            #expect(after.allSatisfy { $0.plan.out.isEmpty })
        }
    }

    @Test func leavingLivelyKeepsOneVisitorWhenAVisitIsDue() {
        var scheduler = PetScheduler(settings: settings)
        var rng = PetRandom(seed: 1)
        _ = scheduler.plan(.fixture(), streak: 0, using: &rng)
        let lively = scheduler.plan(.fixture(now: start + 1300, secondsSinceInput: 180), streak: 0, using: &rng)
        #expect(lively.mode == .lively)
        let back = scheduler.plan(.fixture(now: start + 1301), streak: 0, using: &rng)
        #expect(back.mode == .visitor)
        #expect(back.out.count == 1)
        #expect(back.out.isSubset(of: lively.out))
    }

    @Test func leavingLivelyKeepsTheFavouredBirdAsTheVisitor() {
        var scheduler = PetScheduler(settings: settings)
        var rng = PetRandom(seed: 1)
        _ = scheduler.plan(.fixture(), streak: 0, using: &rng)
        _ = scheduler.plan(.fixture(now: start + 1300, secondsSinceInput: 180, frontApp: "com.figma.Desktop"), streak: 0, using: &rng)
        #expect(scheduler.plan(.fixture(now: start + 1301, frontApp: "com.figma.Desktop"), streak: 0, using: &rng).out == [.peacock])
    }

    @Test func leavingLivelyBeforeAVisitIsDueSendsEveryoneHome() {
        var scheduler = PetScheduler(settings: settings)
        var rng = PetRandom(seed: 1)
        _ = scheduler.plan(.fixture(), streak: 0, using: &rng)
        _ = scheduler.plan(.fixture(now: start + 10, secondsSinceInput: 180), streak: 0, using: &rng)
        #expect(scheduler.plan(.fixture(now: start + 11), streak: 0, using: &rng).out.isEmpty)
    }

    @Test func withNoIdleBirdsNothingComesOut() {
        var scheduler = PetScheduler(settings: settings)
        var rng = PetRandom(seed: 1)
        let plan = scheduler.plan(.fixture(secondsSinceInput: 600, busy: Set(Bird.allCases)), streak: 0, using: &rng)
        #expect(plan.mode == .lively)
        #expect(plan.out.isEmpty)
    }
}
