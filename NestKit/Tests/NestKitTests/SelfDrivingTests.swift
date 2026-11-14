import Foundation
import Testing
@testable import NestKit

struct SelfDrivingTests {
    static let calendar = ClaudeHistoryTests.calendar
    static func monday(_ day: Int = 0, _ hour: Int, _ minute: Int = 0) -> Date { ScheduleTests.monday(day, hour, minute) }

    @Test func activeMinutesOnTheMacCountAsWork() {
        var activity: [Date: Int] = [:]
        for week in 1...2 { activity[Self.monday(-7 * week, 20)] = 25 }
        activity[Self.monday(-7, 21)] = 4
        activity[Self.monday(-14, 21)] = 4
        let pattern = WorkPattern(messages: [], activity: activity, now: Self.monday(0, 8), calendar: Self.calendar)

        #expect(pattern.isYours(Self.monday(0, 20)))
        #expect(!pattern.isYours(Self.monday(0, 21)))
    }

    @Test func recentWeeksCountMoreThanOldOnes() {
        let lastWeek = WorkPattern(messages: [Self.monday(-7, 15)], now: Self.monday(0, 8), calendar: Self.calendar)
        let threeWeeksAgo = WorkPattern(messages: [Self.monday(-21, 15), Self.monday(-29, 15)], now: Self.monday(0, 8),
                                        calendar: Self.calendar)
        #expect(lastWeek.score(Self.monday(0, 15)) == 1.0)
        #expect(!lastWeek.isYours(Self.monday(0, 15)))
        #expect(threeWeeksAgo.score(Self.monday(0, 15)) == 0.5)
        #expect(!threeWeeksAgo.isYours(Self.monday(0, 15)))
    }

    @Test func swiftDecidesWhenYouAreAway() {
        let rule = AwayRule()
        let pattern = ScheduleTests.pattern
        #expect(rule.presence(idle: 14 * 60, at: Self.monday(0, 20), pattern: pattern, hold: false) == "here")
        #expect(rule.presence(idle: 15 * 60, at: Self.monday(0, 20), pattern: pattern, hold: false) == "away")
        #expect(rule.presence(idle: 30 * 60, at: Self.monday(0, 10), pattern: pattern, hold: false) == "here")
        #expect(rule.presence(idle: 60 * 60, at: Self.monday(0, 10), pattern: pattern, hold: false) == "away")
        #expect(rule.presence(idle: 5, at: Self.monday(0, 20), pattern: pattern, hold: false) == "here")
        #expect(rule.presence(idle: 3 * 3600, at: Self.monday(0, 20), pattern: pattern, hold: true) == "here")
    }

    @Test func theActivityLogKeepsMinutesPerHourAndForgetsOldOnes() throws {
        let folder = FileManager.default.temporaryDirectory.appending(path: "SelfDrivingTests-\(UUID().uuidString)")
        defer { try? FileManager.default.removeItem(at: folder) }
        let log = ActivityLog(at: folder.appending(path: "activity.json"))

        try log.record(activeAt: Self.monday(0, 9, 1))
        try log.record(activeAt: Self.monday(0, 9, 2))
        try log.record(activeAt: Self.monday(0, 9, 2))
        try log.record(activeAt: Self.monday(-40, 9, 0))
        try log.record(activeAt: Self.monday(0, 10, 0))

        let hours = try log.hours(now: Self.monday(0, 11))
        #expect(hours[Self.monday(0, 9)] == 2)
        #expect(hours[Self.monday(0, 10)] == 1)
        #expect(hours.count == 2)
    }
}
