import Foundation
import Testing
@testable import NestKit

struct BudgetReserveTests {
    @Test func theReserveIsTheForecastOnceThereIsHistoryAndTheFixedOneBefore() async throws {
        let folder = FileManager.default.temporaryDirectory.appending(path: "BudgetReserveTests-\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: folder) }
        let log = try UsageLog(at: folder.appending(path: "usage.sqlite"))
        let now = UsageForecastTests.day(10)
        try await log.record(task: "T-01", usage: try #require(SessionUsage(output: UsageLogTests.stream(cost: 1, weekly: 0.5))),
                             started: now, ended: now.addingTimeInterval(600))
        let resets = try #require(try await log.entries().last?.limits?.weeklyResets)
        let history = UsageForecastTests.firstWeek.enumerated().map { DayUse(day: UsageForecastTests.day($0.offset), used: $0.element) }
        let forecast = UsageForecast(history: history, calendar: UsageForecastTests.calendar)

        let fixed = Budget(rules: BudgetRules(reserve: 0.25), log: log, calendar: UsageForecastTests.calendar, now: { now })
        let learned = Budget(rules: BudgetRules(reserve: 0.25), log: log, calendar: UsageForecastTests.calendar, now: { now },
                             forecast: forecast)

        #expect(try await fixed.reserve() == 0.25)
        #expect(try await learned.reserve() == forecast.reserve(from: now, until: resets, orElse: 0.25))
    }
}
