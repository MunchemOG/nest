import Foundation
import Testing
@testable import NestKit

struct BirdQuirksTests {
    struct Expected: Sendable, CustomTestStringConvertible {
        let bird: Bird
        let bravery: Double
        let curiosity: Double
        let fleeDistance: Double
        let rushSpeed: Double
        let dwell: ClosedRange<TimeInterval>
        let habit: PetActivity
        let hover: PetReaction
        let rush: PetReaction
        let near: PetReaction?
        let approachesStillPointer: Bool
        let followsPointer: Bool
        let returnsAfterFleeing: Bool
        let homeReaction: PetReaction?
        let apps: Set<String>

        var testDescription: String { bird.name }
    }

    /// The spec's personalities as numbers, copied from the pet brain plan.
    static let expected: [Expected] = [
        Expected(bird: .wren, bravery: 0.9, curiosity: 0.5, fleeDistance: 40, rushSpeed: 1500, dwell: 4...10,
                 habit: .hopping, hover: .hopCloser, rush: .dartAway, near: nil,
                 approachesStillPointer: true, followsPointer: false, returnsAfterFleeing: false, homeReaction: nil,
                 apps: ["com.apple.finder", "com.apple.systempreferences"]),
        Expected(bird: .swift, bravery: 0.1, curiosity: 0.3, fleeDistance: 160, rushSpeed: 400, dwell: 2...5,
                 habit: .looping, hover: .tiltHead, rush: .dartAway, near: nil,
                 approachesStillPointer: false, followsPointer: false, returnsAfterFleeing: true, homeReaction: nil,
                 apps: ["com.apple.dt.Xcode", "com.microsoft.VSCode", "com.todesktop.230313mzl4w4u92", "com.apple.Terminal"]),
        Expected(bird: .crow, bravery: 0.6, curiosity: 1.0, fleeDistance: 100, rushSpeed: 900, dwell: 5...12,
                 habit: .perched, hover: .tiltHead, rush: .dartAway, near: nil,
                 approachesStillPointer: false, followsPointer: true, returnsAfterFleeing: false, homeReaction: nil,
                 apps: ["com.apple.Safari", "com.google.Chrome", "company.thebrowser.Browser", "org.mozilla.firefox"]),
        Expected(bird: .owl, bravery: 0.8, curiosity: 0.2, fleeDistance: 24, rushSpeed: 3000, dwell: 20...60,
                 habit: .dozing, hover: .blink, rush: .dartAway, near: .watch,
                 approachesStillPointer: false, followsPointer: false, returnsAfterFleeing: false, homeReaction: nil,
                 apps: []),
        Expected(bird: .magpie, bravery: 0.7, curiosity: 0.8, fleeDistance: 80, rushSpeed: 1000, dwell: 4...9,
                 habit: .hopping, hover: .stealSparkle, rush: .dartAway, near: nil,
                 approachesStillPointer: true, followsPointer: false, returnsAfterFleeing: false, homeReaction: .carryGlint,
                 apps: ["com.apple.Notes", "md.obsidian"]),
        Expected(bird: .peacock, bravery: 0.5, curiosity: 0.4, fleeDistance: 120, rushSpeed: 700, dwell: 8...15,
                 habit: .preening, hover: .fanTail, rush: .huff, near: nil,
                 approachesStillPointer: false, followsPointer: false, returnsAfterFleeing: false, homeReaction: nil,
                 apps: ["com.figma.Desktop", "com.bohemiancoding.sketch3"]),
    ]

    @Test(arguments: expected)
    func quirksMatchTheSpec(_ e: Expected) {
        let quirks = BirdQuirks.of(e.bird)
        #expect(quirks.bravery == e.bravery)
        #expect(quirks.curiosity == e.curiosity)
        #expect(quirks.fleeDistance == e.fleeDistance)
        #expect(quirks.rushSpeed == e.rushSpeed)
        #expect(quirks.dwell == e.dwell)
        #expect(quirks.habit == e.habit)
        #expect(quirks.hover == e.hover)
        #expect(quirks.rush == e.rush)
        #expect(quirks.near == e.near)
        #expect(quirks.approachesStillPointer == e.approachesStillPointer)
        #expect(quirks.followsPointer == e.followsPointer)
        #expect(quirks.returnsAfterFleeing == e.returnsAfterFleeing)
        #expect(quirks.homeReaction == e.homeReaction)
        #expect(quirks.apps == e.apps)
    }

    @Test func everyBirdIsPinned() {
        #expect(Set(Self.expected.map(\.bird)) == Set(Bird.allCases))
    }

    @Test func noAppIsFavouredByTwoBirds() {
        let all = Bird.allCases.map { BirdQuirks.of($0).apps }
        #expect(all.map(\.count).reduce(0, +) == Set(all.joined()).count)
    }

    @Test func shapesFollowActivity() {
        let glyphs = Set(PetActivity.allCases.filter { $0.shape == .glyph })
        #expect(glyphs == [.home, .perched, .preening, .hopping, .dozing])
    }
}
