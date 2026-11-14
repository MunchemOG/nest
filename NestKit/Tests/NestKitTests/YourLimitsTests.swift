import Foundation
import Testing
@testable import NestKit

struct YourLimitsTests {
    static let calendar = BudgetTests.calendar
    static func limits(weekly: Double) -> LimitSnapshot { BudgetTests.limits(weekly: weekly) }
    static let noon = BudgetTests.tuesday(12)

    @Test func withAFortyPercentCapSwiftPausesBeforeCrossingIt() {
        let rules = BudgetRules(reserve: 0, weeklyCap: 0.4)
        #expect(rules.decide(at: Self.noon, limits: Self.limits(weekly: 0.36), nextTask: 0.03, calendar: Self.calendar) == .run)
        let decision = rules.decide(at: Self.noon, limits: Self.limits(weekly: 0.38), nextTask: 0.03, calendar: Self.calendar)
        #expect(decision == .pause("Keeping to your cap: 38% of the week is used, the next task needs about 3%, and your cap is 40%."))
    }

    @Test func aForecastStricterThanTheCapWins() {
        let rules = BudgetRules(reserve: 0.7, weeklyCap: 0.4)
        let decision = rules.decide(at: Self.noon, limits: Self.limits(weekly: 0.28), nextTask: 0.03, calendar: Self.calendar)
        #expect(decision == .pause("Keeping the reserve: 28% of the week is used, the next task needs about 3%, and 70% is kept back."))
    }

    @Test func aForecastLooserThanTheCapNeverLoosensIt() {
        let rules = BudgetRules(reserve: 0.1, weeklyCap: 0.4)
        let decision = rules.decide(at: Self.noon, limits: Self.limits(weekly: 0.38), nextTask: 0.03, calendar: Self.calendar)
        #expect(decision == .pause("Keeping to your cap: 38% of the week is used, the next task needs about 3%, and your cap is 40%."))
    }

    @Test func theFiveHourCapIsYours() {
        let limits = SwiftLimits(weeklyCap: 0.6, fiveHourCap: 0.8)
        let rules = limits.rules(reserve: 0.25)
        #expect(rules.weeklyCap == 0.6)
        #expect(rules.fiveHourCeiling == 0.8)
        #expect(rules.reserve == 0.25)
        let full = LimitSnapshot(fiveHour: 0.81, fiveHourResets: BudgetTests.tuesday(14), weekly: 0.1, weeklyResets: BudgetTests.tuesday(23))
        #expect(rules.decide(at: Self.noon, limits: full, nextTask: 0.03, calendar: Self.calendar)
                == .pause("The five-hour limit is nearly full; it resets at 14:00."))
    }

    @Test func limitsSurviveBeingSaved() throws {
        let limits = SwiftLimits(weeklyCap: 0.55, fiveHourCap: 0.7)
        let saved = try JSONEncoder().encode(limits)
        #expect(try JSONDecoder().decode(SwiftLimits.self, from: saved) == limits)
        #expect(SwiftLimits.standard == SwiftLimits(weeklyCap: 0.75, fiveHourCap: 0.95))
    }

    /// Robotics then the Nest, back to back: each cost $1 and used 10% of the week.
    func sharedLog() async throws -> (UsageLog, URL) {
        let folder = FileManager.default.temporaryDirectory.appending(path: "YourLimitsTests-\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        let log = try UsageLog(at: folder.appending(path: "usage.sqlite"))
        try await log.record(task: "R-01", project: "robotics",
                             usage: try #require(SessionUsage(output: UsageLogTests.stream(cost: 1, weekly: 0.1))),
                             started: UsageLogTests.at(9, 0), ended: UsageLogTests.at(9, 30))
        try await log.record(task: "Y-01", project: "nest",
                             usage: try #require(SessionUsage(output: UsageLogTests.stream(cost: 1, weekly: 0.2))),
                             started: UsageLogTests.at(9, 31), ended: UsageLogTests.at(10, 0))
        return (log, folder)
    }

    @Test func theLogKnowsWhichProjectEachSessionWasFor() async throws {
        let (log, folder) = try await sharedLog()
        defer { try? FileManager.default.removeItem(at: folder) }
        #expect(try await log.entries().map(\.project) == ["robotics", "nest"])
    }

    @Test func aProjectOverItsSharePausesWhileAnotherRuns() async throws {
        let (log, folder) = try await sharedLog()
        defer { try? FileManager.default.removeItem(at: folder) }
        let rules = BudgetRules(reserve: 0, weeklyCap: 0.4)
        let now: @Sendable () -> Date = { UsageLogTests.at(11, 0) }

        let robotics = Budget(rules: rules, log: log, now: now, project: ProjectShare(project: "robotics", share: 0.25))
        let nest = Budget(rules: rules, log: log, now: now, project: ProjectShare(project: "nest", share: 0.75))

        #expect(try await robotics.decide() == .pause("robotics has used its share: 10% of the week, the next task needs about 10%, and its share is 10%."))
        #expect(try await nest.decide() == .run)
    }

    @Test func theTasksLeftFollowTheCapAsYouMoveIt() async throws {
        let (log, folder) = try await sharedLog()
        defer { try? FileManager.default.removeItem(at: folder) }
        let budget = Budget(rules: BudgetRules(reserve: 0, weeklyCap: 0.4), log: log, now: { UsageLogTests.at(11, 0) })

        #expect(try await budget.tasksLeft() == 2)
        #expect(try await budget.tasksLeft(underCap: 0.8) == 6)
        #expect(try await budget.tasksLeft(underCap: 0.1) == 0)
    }
}
