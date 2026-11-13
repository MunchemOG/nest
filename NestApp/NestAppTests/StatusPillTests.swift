import NestKit
import SwiftUI
import Testing
@testable import NestApp

@MainActor
struct StatusPillTests {
    static let kinds: [StatusPillKind] =
        Bird.allCases.flatMap { bird in BirdStatus.allCases.map { StatusPillKind.bird(bird, $0) } }
        + [.success("Passed"), .warning("Needs a look"), .danger("Failed")]

    @Test func onlyAnActiveBirdBreathes() {
        for kind in Self.kinds {
            let active = if case .bird(_, .active) = kind { true } else { false }
            #expect(kind.breathes(reduceMotion: false) == active, "\(kind)")
        }
    }

    @Test func motionStopsUnderReducedMotion() {
        for kind in Self.kinds {
            #expect(kind.breathes(reduceMotion: true) == false, "\(kind)")
        }
    }

    @Test func statusColoursAlwaysComeWithAnIconAndAWord() {
        for kind in Self.kinds where [.statusSuccess, .statusWarning, .statusDanger].contains(kind.accent) {
            #expect(kind.symbol != nil, "\(kind)")
            #expect(!kind.word.isEmpty, "\(kind)")
        }
    }

    @Test(arguments: Bird.allCases)
    func anActiveBirdGlowsInItsOwnColour(_ bird: Bird) {
        #expect(StatusPillKind.bird(bird, .active).accent == bird.color)
        #expect(StatusPillKind.bird(bird, .active).accentRest == bird.tint)
    }

    @Test func aPausedBirdShowsTheWarningColourAndAPauseIcon() {
        let kind = StatusPillKind.bird(.crow, .paused)
        #expect(kind.accent == .statusWarning)
        #expect(kind.symbol == "pause.fill")
        #expect(kind.word == "Paused")
    }

    @Test(arguments: BirdStatus.allCases)
    func everyBirdStatusMatchesItsSnapshot(_ status: BirdStatus) throws {
        try Snapshot.expect(StatusPill(.bird(.swift, status)), named: "status-\(status)")
    }

    @Test func everyFlagMatchesItsSnapshot() throws {
        try Snapshot.expect(StatusPill(.success("Passed")), named: "status-success")
        try Snapshot.expect(StatusPill(.warning("Needs a look")), named: "status-warning")
        try Snapshot.expect(StatusPill(.danger("Failed")), named: "status-danger")
    }

    @Test func anActivePillRendersStillUnderReducedMotion() throws {
        let pill = StatusPill(.bird(.swift, .active)).environment(\.reduceMotionOverride, true)
        try Snapshot.expect(pill, named: "status-active-reduced-motion")
    }
}
