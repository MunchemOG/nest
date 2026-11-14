import NestKit
import Testing
@testable import NestApp

@MainActor
struct PresenceSwitchTests {
    @Test func flippingTheSwitchPublishesPresenceOntoTheTimeline() {
        let model = HomeModel()
        let presence = PresenceSwitch(model: model)
        #expect(presence.isHere == false)

        presence.isHere = true

        #expect(model.events.last?.topic == .owlPresenceChanged)
        #expect(model.events.last?.data["to"] == .string("here"))
        #expect(model.facts.presence == "here")
        #expect(presence.isHere == true)

        presence.isHere = false

        #expect(model.events.last?.data == ["to": .string("away"), "was": .string("here")])
        #expect(presence.isHere == false)
    }

    @Test func swiftIsToldEveryFlipEvenWhenTheTimelineAlreadySaysSo() {
        let model = HomeModel()
        model.receive(.presenceChanged(to: "away", was: "here"))
        let presence = PresenceSwitch(model: model)
        var told: [String] = []
        presence.tellSwift = { told.append($0) }

        presence.isHere = false
        presence.isHere = true

        #expect(told == ["away", "here"])
    }
}
