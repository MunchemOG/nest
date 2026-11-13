import NestKit
import SwiftUI
import Testing
@testable import NestApp

@MainActor
struct BirdAvatarTests {
    @Test func sizesAndCornersComeFromTokens() {
        #expect(BirdAvatarSize.small.side == NestSpace.s5)
        #expect(BirdAvatarSize.medium.side == NestSpace.s7)
        #expect(BirdAvatarSize.large.side == NestSpace.s9)
        #expect(BirdAvatarSize.small.cornerRadius == NestRadius.sm)
        #expect(BirdAvatarSize.medium.cornerRadius == NestRadius.lg)
        #expect(BirdAvatarSize.large.cornerRadius == NestRadius.tile)
    }

    @Test(arguments: BirdAvatarSize.allCases)
    func theBadgeIsSmallerThanTheTile(_ size: BirdAvatarSize) {
        #expect(size.badge < size.side / 2)
    }

    @Test func onlyAPausedBirdLosesItsColour() {
        #expect(BirdAvatarState.paused.isGrayscale)
        #expect(!BirdAvatarState.active.isGrayscale)
        #expect(!BirdAvatarState.resting.isGrayscale)
    }

    @Test func badgesMatchTheState() {
        #expect(BirdAvatarState.resting.badge == .none)
        #expect(BirdAvatarState.active.badge == .dot)
        #expect(BirdAvatarState.paused.badge == .symbol("pause.fill"))
    }

    @Test(arguments: Bird.allCases)
    func theAvatarSaysWhoAndHow(_ bird: Bird) {
        #expect(BirdAvatar(bird, state: .active).accessibilityText == "\(bird.name), working")
        #expect(BirdAvatar(bird, state: .paused).accessibilityText == "\(bird.name), paused")
        #expect(BirdAvatar(bird, state: .resting).accessibilityText == "\(bird.name), resting")
    }

    @Test(arguments: Bird.allCases)
    func everyBirdAndStateMatchesItsSnapshot(_ bird: Bird) throws {
        for state in BirdAvatarState.allCases {
            try Snapshot.expect(BirdAvatar(bird, size: .medium, state: state), named: "avatar-\(bird)-\(state)")
        }
    }

    @Test(arguments: BirdAvatarSize.allCases)
    func everySizeMatchesItsSnapshot(_ size: BirdAvatarSize) throws {
        let row = HStack(spacing: NestSpace.s3) {
            ForEach(BirdAvatarState.allCases, id: \.self) { BirdAvatar(.owl, size: size, state: $0) }
        }
        try Snapshot.expect(row, named: "avatar-size-\(size)")
    }
}
