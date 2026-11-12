import Foundation
import Testing
@testable import NestKit

struct PetSettingsTests {
    @Test func goHomeIsTheSlowToken() {
        #expect(PetSettings.goHome == 0.42)
    }

    @Test func defaultsMatchTheSpec() {
        let settings = PetSettings()
        #expect(settings.visitGap == 600...1200)
        #expect(settings.visitLength == 60...240)
        #expect(settings.breakAfter == 3000)
        #expect(settings.breakPause == 300)
        #expect(settings.breakLength == 180)
        #expect(settings.breakBirds == 2...3)
        #expect(settings.breakCooldown == 1200)
        #expect(settings.livelyAfter == 180)
        #expect(settings.livelySettle == 2)
        #expect(settings.flightTime == 1.5)
        #expect(settings.nightStartHour == 23)
        #expect(settings.nightEndHour == 5)
        #expect(settings.meetingApps == ["us.zoom.xos", "com.microsoft.teams2", "com.apple.FaceTime"])
        #expect(settings.perchSpacing == 32)
        #expect(settings.hoverRadius == 28)
        #expect(settings.stillSpeed == 60)
        #expect(settings.approachRadius == 220)
        #expect(settings.approachAfter == 2)
        #expect(settings.sitAfter == 4)
        #expect(settings.followDistance == 120)
    }

    @Test func settingsRoundTripThroughJSON() throws {
        var settings = PetSettings()
        settings.visitGap = 300...900
        let data = try JSONEncoder().encode(settings)
        #expect(try JSONDecoder().decode(PetSettings.self, from: data) == settings)
    }
}
