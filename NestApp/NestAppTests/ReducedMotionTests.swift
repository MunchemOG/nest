import Foundation
import NestKit
import Testing
@testable import NestApp

@MainActor
struct ReducedMotionTests {
    @Test func withReducedMotionNothingMoves() {
        #expect(!ActivityPanel.rowsSlide(reduceMotion: true))
        #expect(!ModeSwitch.knobSlides(reduceMotion: true))
        #expect(!FlockMemberRow.lifts(reduceMotion: true))
        #expect(!TypingDots.steps(reduceMotion: true))
        for bird in Bird.allCases {
            #expect(!StatusPillKind.bird(bird, .active).breathes(reduceMotion: true))
        }
    }

    @Test func withoutItTheyDo() {
        #expect(ActivityPanel.rowsSlide(reduceMotion: false))
        #expect(ModeSwitch.knobSlides(reduceMotion: false))
        #expect(FlockMemberRow.lifts(reduceMotion: false))
        #expect(TypingDots.steps(reduceMotion: false))
    }

    @Test func theStudioIsToldToHoldStill() {
        let model = HomeModel()
        var state = model.studioState
        state.reduceMotion = true
        #expect(state.script.contains("\"reduceMotion\":true"))
    }

    @Test func theStudioPageObeysTheSwitch() throws {
        let page = try String(contentsOf: try #require(Bundle.main.url(forResource: "studio", withExtension: "html")), encoding: .utf8)
        #expect(page.contains("let REDUCED"))
        #expect(page.contains("REDUCED = state.reduceMotion"))
    }
}
