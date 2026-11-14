import Foundation
import NestKit
import Testing
@testable import NestApp

@MainActor
struct StudioClickTests {
    @Test func clickingSwiftInTheStudioOpensItsPageAndFlysTheCameraToIt() {
        let model = HomeModel()

        model.studioClicked(.swift)

        #expect(model.closeUp == .swift)
        #expect(model.swiftPage != nil)
        #expect(model.studioState.focus == "swift")
        #expect(model.studioState.script.contains("\"focus\":\"swift\""))
    }

    @Test func clickingEmptySpaceClosesTheCloseUp() {
        let model = HomeModel()
        model.studioClicked(.swift)

        model.studioClicked(nil)

        #expect(model.closeUp == nil)
        #expect(model.studioState.focus == nil)
        #expect(model.studioState.script.contains("\"focus\":null"))
    }

    @Test func aBirdWithNoPageYetLeavesHomeAsItIs() {
        let model = HomeModel()

        model.studioClicked(.crow)

        #expect(model.closeUp == nil)
        #expect(model.studioState.focus == nil)
    }

    @Test func theStudiosMessageNamesTheBirdOrNothing() {
        #expect(StudioView.click(from: ["open": "swift"]) == .some(.swift))
        #expect(StudioView.click(from: ["open": NSNull()]) == .some(nil))
        #expect(StudioView.click(from: ["open": "heron"]) == nil)
        #expect(StudioView.click(from: "swift") == nil)
    }
}
