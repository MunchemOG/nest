import NestKit
import SwiftUI
import Testing
@testable import NestApp

@MainActor
struct NestTagTests {
    @Test func accentTagsUseTintAndSoft() {
        #expect(NestTagKind.clay.fill == .clayTint && NestTagKind.clay.label == .claySoft)
        #expect(NestTagKind.sage.fill == .sageTint && NestTagKind.sage.label == .sageSoft)
        #expect(NestTagKind.lagoon.fill == .lagoonTint && NestTagKind.lagoon.label == .lagoonSoft)
    }

    @Test(arguments: Bird.allCases)
    func aBirdTagUsesOnlyThatBirdsColours(_ bird: Bird) {
        let kind = NestTagKind.bird(bird)
        #expect(kind.fill == bird.tint)
        #expect(kind.label == bird.color)
    }

    @Test func aSelectedTagGainsAnEdge() {
        for kind in NestTagKind.allCases {
            #expect(kind.border(selected: false) == nil, "\(kind)")
            #expect(kind.border(selected: true) != nil, "\(kind)")
        }
    }

    @Test(arguments: NestTagKind.allCases)
    func everyKindAndStateMatchesItsSnapshot(_ kind: NestTagKind) throws {
        try Snapshot.expect(NestTag("Robotics", kind: kind), named: "tag-\(kind.name)-rest")
        try Snapshot.expect(NestTag("Robotics", kind: kind, isSelected: true), named: "tag-\(kind.name)-selected")
    }
}
