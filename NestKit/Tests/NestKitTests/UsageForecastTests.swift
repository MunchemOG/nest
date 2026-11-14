import Foundation
import Testing
@testable import NestKit

struct UsageForecastTests {
    static var calendar: Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "UTC")!
        return calendar
    }

    /// 2026-11-01 is a Sunday.
    static func day(_ n: Int) -> Date {
        calendar.date(from: DateComponents(year: 2026, month: 11, day: 1 + n))!
    }

    /// Your share of the weekly limit each day: light weekends, heavy robotics Tuesdays and Thursdays.
    static let firstWeek: [Double] = [0.02, 0.05, 0.11, 0.04, 0.12, 0.05, 0.03]
    static let secondWeek: [Double] = [0.025, 0.055, 0.125, 0.035, 0.14, 0.06, 0.02]

    @Test func overAWeekOfLoggedDaysTheForecastLeavesAtLeastWhatYouActuallyUsedOnEveryDay() {
        var history = Self.firstWeek.enumerated().map { DayUse(day: Self.day($0.offset), used: $0.element) }
        for (offset, used) in Self.secondWeek.enumerated() {
            let today = Self.day(7 + offset)
            let forecast = UsageForecast(history: history, calendar: Self.calendar)
            #expect(forecast.forDay(today) >= used, "the forecast for day \(7 + offset) left less than you used")
            history.append(DayUse(day: today, used: used))
        }
    }

    @Test func theReserveCoversEveryDayLeftBeforeTheWeekResets() {
        let history = Self.firstWeek.enumerated().map { DayUse(day: Self.day($0.offset), used: $0.element) }
        let forecast = UsageForecast(history: history, calendar: Self.calendar)
        // From Wednesday (day 10) to the reset on Saturday (day 13): Wednesday, Thursday and Friday.
        let reserve = forecast.reserve(from: Self.day(10), until: Self.day(13))
        let expected = [Self.day(10), Self.day(11), Self.day(12)].map(forecast.forDay).reduce(0, +)
        #expect(abs(reserve - expected) < 1e-9)
        #expect(forecast.forDay(Self.day(11)) > forecast.forDay(Self.day(13)), "robotics Thursday needs more than Saturday")
    }

    @Test func withNoHistoryTheForecastFallsBackToTheFixedReserve() {
        let forecast = UsageForecast(history: [], calendar: Self.calendar)
        #expect(forecast.reserve(from: Self.day(10), until: Self.day(13), orElse: 0.25) == 0.25)
    }

    @Test func swiftKeepsTheForecastBackInsteadOfTheFixedReserve() async throws {
        let folder = FileManager.default.temporaryDirectory.appending(path: "UsageForecastTests-\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: folder) }
        let log = try UsageLog(at: folder.appending(path: "usage.sqlite"))
        // The week is 50% used and resets on Saturday; it is Wednesday morning.
        let limits = LimitSnapshot(fiveHour: 0.1, fiveHourResets: Self.day(10), weekly: 0.5, weeklyResets: Self.day(13))
        try await log.record(task: "T-01", usage: try #require(SessionUsage(output: UsageLogTests.stream(cost: 1, weekly: limits.weekly))),
                             started: Self.day(10), ended: Self.day(10).addingTimeInterval(600))
        let heavy = Self.firstWeek.enumerated().map { DayUse(day: Self.day($0.offset), used: $0.element * 4) }
        let budget = Budget(rules: BudgetRules(reserve: 0.05), log: log, calendar: Self.calendar,
                            now: { Self.day(10).addingTimeInterval(3600) },
                            forecast: UsageForecast(history: heavy, calendar: Self.calendar))
        let decision = try await budget.decide()
        guard case .pause(let why) = decision else {
            Issue.record("Swift ran into the days you will need")
            return
        }
        #expect(why.hasPrefix("Keeping the reserve: 50% of the week is used"))
    }

    @Test func yourDailyUseComesFromTheLog() async throws {
        let folder = FileManager.default.temporaryDirectory.appending(path: "UsageForecastTests-\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: folder) }
        let log = try UsageLog(at: folder.appending(path: "usage.sqlite"))
        // Two back-to-back sessions set the rate (1% a dollar), then a gap with 4% of your own chats.
        let sessions: [(Double, Double, Double)] = [(0, 1, 0.40), (0.01, 1, 0.41), (6, 1, 0.46)]
        for (hours, cost, weekly) in sessions {
            let start = Self.day(3).addingTimeInterval(hours * 3600)
            try await log.record(task: "T", usage: try #require(SessionUsage(output: UsageLogTests.stream(cost: cost, weekly: weekly))),
                                 started: start, ended: start.addingTimeInterval(30))
        }
        let days = try await log.yourUse(byDayIn: Self.calendar)
        #expect(days.map(\.day) == [Self.day(3)])
        #expect(abs((days.first?.used ?? 0) - 0.04) < 1e-9)
    }
}
