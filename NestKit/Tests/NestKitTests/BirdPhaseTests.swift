import Testing
@testable import NestKit

struct BirdPhaseTests {
    @Test func everyBirdWakesInItsBuildPhase() {
        #expect(Bird.swift.buildPhase == 2)
        #expect(Bird.wren.buildPhase == 3)
        #expect(Bird.magpie.buildPhase == 4)
        #expect(Bird.crow.buildPhase == 5)
        #expect(Bird.owl.buildPhase == 6)
        #expect(Bird.peacock.buildPhase == 7)
    }
}
