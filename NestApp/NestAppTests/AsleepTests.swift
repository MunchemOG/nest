import Foundation
import NestKit
import SwiftUI
import Testing
@testable import NestApp

@MainActor
struct AsleepTests {
    @Test func withAnEmptySourceAllSixBirdsShowAsleep() async {
        let model = HomeModel()
        await model.listen(to: ReplaySource(events: [], clock: ImmediateClock(), speed: 1))
        for bird in Bird.allCases {
            #expect(model.flock.status(of: bird) == .asleep)
            #expect(model.studioState.statuses[bird.rawValue] == "asleep")
            #expect(model.tagLine(for: bird) == "Asleep until Phase \(bird.buildPhase)")
        }
    }

    @Test func theHeadlineSaysTheFlockIsAsleep() {
        let headline = HomeModel().headline
        #expect(headline.main == "All six are asleep.")
        #expect(headline.sub == "The first wakes in Phase 2.")
    }

    @Test func aBirdWakesOnceItIsHeardFrom() throws {
        let model = HomeModel()
        model.receive(try #require(try DemoDay.events().first))
        #expect(model.studioState.statuses["swift"] != "asleep")
        #expect(model.studioState.statuses["wren"] == "asleep")
        #expect(model.headline.main != "All six are asleep.")
    }

    @Test func anAsleepAvatarHasItsOwnLook() {
        #expect(BirdAvatarState(.asleep) == .asleep)
        #expect(BirdAvatarState.asleep.badge == .symbol("moon.zzz.fill"))
        #expect(BirdAvatarState.asleep.isGrayscale)
        #expect(BirdAvatarState.asleep.word == "asleep")
    }

    @Test func anEmptyHomeAndTimelineRenderWithoutCrashing() throws {
        let model = HomeModel()
        try Snapshot.expect(HomeScreen(model: model).frame(width: NestSpace.s10 * 9, height: NestSpace.s10 * 6), named: "home-asleep", rendering: .window)
        try Snapshot.expect(TimelineScreen(model: model).frame(width: NestSpace.s10 * 6, height: NestSpace.s10 * 3), named: "timeline-empty", rendering: .window)
    }
}
