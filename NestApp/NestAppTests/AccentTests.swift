import NestKit
import SwiftUI
import Testing
@testable import NestApp

@MainActor
struct AccentTests {
    @Test func accentsComeFromTheirTokens() {
        #expect(NestAccent.clay.fill == .clay && NestAccent.clay.tint == .clayTint && NestAccent.clay.soft == .claySoft && NestAccent.clay.deep == .clayDeep)
        #expect(NestAccent.sage.fill == .sage && NestAccent.sage.tint == .sageTint && NestAccent.sage.soft == .sageSoft && NestAccent.sage.deep == .sageDeep)
        #expect(NestAccent.lagoon.fill == .lagoon && NestAccent.lagoon.tint == .lagoonTint && NestAccent.lagoon.soft == .lagoonSoft && NestAccent.lagoon.deep == .lagoonDeep)
        #expect(NestAccent(name: "lagoon") == .lagoon)
        #expect(NestAccent(name: "something else") == .clay)
        #expect(NestAccent(name: nil) == .clay)
    }

    @Test(arguments: NestAccent.allCases)
    func changingTheAccentRecoloursEveryPrimaryControl(_ accent: NestAccent) {
        #expect(NestButtonPalette(.primary, .rest, accent: accent).fill == accent.fill)
        #expect(NestButtonPalette(.primary, .hover, accent: accent).fill == accent.soft)
        #expect(NestButtonPalette(.primary, .pressed, accent: accent).fill == accent.deep)
        #expect(NestCardPalette(.selected, accent: accent).border == accent.fill)
        #expect(RailButtonPalette(isSelected: true, isHovered: false, accent: accent).marker == accent.fill)
        #expect(NestTagKind.clay.fill(accent: accent) == accent.tint)
        #expect(NestTagKind.clay.label(accent: accent) == accent.soft)
        let ring = FocusRing<Capsule>.colours(accent: accent)
        #expect(ring.contains { $0.red == accent.fill.red && $0.green == accent.fill.green && $0.blue == accent.fill.blue })
        #expect(!ring.contains { $0 == .clay } || accent == .clay)
    }

    @Test func birdColoursNeverFollowTheAccent() {
        for bird in Bird.allCases {
            #expect(NestTagKind.bird(bird).fill(accent: .lagoon) == bird.tint)
        }
    }

    @Test func wrensLookSetsTheAccent() throws {
        let model = HomeModel()
        let events = try DemoDay.events()
        let morning = try #require(events.firstIndex { $0.summary == "Wren set the Morning look: dunes, light, clay accent" })
        events[...morning].forEach(model.receive)
        #expect(model.accent == .clay)
        events[(morning + 1)...].forEach(model.receive)
        #expect(model.accent == .lagoon)
    }

    @Test(arguments: NestAccent.allCases)
    func primaryButtonsMatchTheirSnapshotInEachAccent(_ accent: NestAccent) throws {
        let row = HStack(spacing: NestSpace.s2) {
            NestButtonFace("Build it", variant: .primary, size: .regular, state: .rest)
            NestButtonFace("Build it", variant: .primary, size: .regular, state: .focused)
        }
        .environment(\.nestAccent, accent)
        try Snapshot.expect(row, named: "accent-\(accent.rawValue)")
    }
}
