import Testing
@testable import NestKit

struct BirdTintTests {
    @Test func everyBirdHasItsOwnTint() {
        #expect(Bird.wren.tint == .flockWrenTint)
        #expect(Bird.swift.tint == .flockSwiftTint)
        #expect(Bird.crow.tint == .flockCrowTint)
        #expect(Bird.owl.tint == .flockOwlTint)
        #expect(Bird.magpie.tint == .flockMagpieTint)
        #expect(Bird.peacock.tint == .flockPeacockTint)
    }

    @Test(arguments: Bird.allCases)
    func aTintIsItsColourWashedOut(_ bird: Bird) {
        #expect(bird.tint.red == bird.color.red)
        #expect(bird.tint.green == bird.color.green)
        #expect(bird.tint.blue == bird.color.blue)
        #expect(bird.tint.alpha < bird.color.alpha)
    }
}
