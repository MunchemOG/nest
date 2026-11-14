import Foundation
import NestKit
import Testing
@testable import NestApp

@MainActor
struct AutoPresenceTests {
    nonisolated static let calendar: Calendar = {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "UTC")!
        return calendar
    }()

    /// 2026-11-16 is a Monday.
    nonisolated static func monday(_ day: Int, _ hour: Int, _ minute: Int = 0) -> Date {
        calendar.date(from: DateComponents(year: 2026, month: 11, day: 16 + day, hour: hour, minute: minute))!
    }

    final class Clock: @unchecked Sendable {
        var now: Date
        var idle: TimeInterval = 0
        init(_ now: Date) { self.now = now }
    }

    func setUp(messages: [Date] = []) throws -> (AutoPresence, PresenceSwitch, Clock, URL) {
        let folder = FileManager.default.temporaryDirectory.appending(path: "AutoPresenceTests-\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        let clock = Clock(Self.monday(0, 20))
        let presence = PresenceSwitch(model: HomeModel())
        let auto = AutoPresence(presence: presence, log: ActivityLog(at: folder.appending(path: "activity.json")),
                                messages: { messages }, idle: { clock.idle }, now: { clock.now }, calendar: Self.calendar)
        return (auto, presence, clock, folder)
    }

    @Test func idleInAGapMakesSwiftAwayAndTouchingTheMacBringsYouBack() throws {
        let (auto, presence, clock, folder) = try setUp()
        defer { try? FileManager.default.removeItem(at: folder) }
        var told: [String] = []
        presence.tellSwift = { told.append($0) }

        auto.tick()
        clock.idle = 16 * 60
        auto.tick()
        clock.idle = 2
        auto.tick()

        #expect(told == ["here", "away", "here"])
        #expect(presence.isHere)
        #expect(auto.status == "You're here. Swift waits.")
    }

    @Test func inYourHoursSwiftWaitsForAnHourIdle() throws {
        let worked = (1...3).flatMap { week in (0..<5).map { Self.monday($0 - 7 * week, 20, 15) } }
        let (auto, presence, clock, folder) = try setUp(messages: worked)
        defer { try? FileManager.default.removeItem(at: folder) }

        clock.idle = 30 * 60
        auto.tick()
        #expect(presence.isHere)
        clock.idle = 61 * 60
        auto.tick()
        #expect(!presence.isHere)
        #expect(auto.status == "You're away. Swift may work.")
    }

    @Test func holdingSwiftKeepsYouHere() throws {
        let (auto, presence, clock, folder) = try setUp()
        defer { try? FileManager.default.removeItem(at: folder) }
        auto.hold = true
        clock.idle = 5 * 3600
        auto.tick()
        #expect(presence.isHere)
        #expect(auto.status == "Swift is held.")
    }

    @Test func activeMinutesAreRecordedForLearningYourWeek() throws {
        let (auto, _, clock, folder) = try setUp()
        defer { try? FileManager.default.removeItem(at: folder) }
        clock.idle = 3
        auto.tick()
        clock.now = clock.now.addingTimeInterval(60)
        auto.tick()
        clock.idle = 20 * 60
        clock.now = clock.now.addingTimeInterval(60)
        auto.tick()
        let hours = try ActivityLog(at: folder.appending(path: "activity.json")).hours(now: clock.now)
        #expect(hours.values.reduce(0, +) == 2)
    }
}
