import Foundation
import Testing
@testable import NestKit

struct BudgetTests {
    static let utc = TimeZone(identifier: "UTC")!
    static var calendar: Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = utc
        return calendar
    }

    /// 2026-11-17 is a Tuesday.
    static func tuesday(_ hour: Int, _ minute: Int = 0) -> Date {
        calendar.date(from: DateComponents(year: 2026, month: 11, day: 17, hour: hour, minute: minute))!
    }

    static func limits(weekly: Double, fiveHour: Double = 0.1) -> LimitSnapshot {
        LimitSnapshot(fiveHour: fiveHour, fiveHourResets: tuesday(23), weekly: weekly, weeklyResets: tuesday(23))
    }

    /// Robotics on Tuesdays and Thursdays, 16:00 to 20:00.
    static let robotics = BlockedHours(weekdays: [3, 5], from: 16 * 60, to: 20 * 60, reason: "Robotics hours")

    @Test func withTheReserveSetHighOnPurposeSwiftPausesInsteadOfRunning() async throws {
        let repo = try await TempRepo()
        defer { repo.remove() }
        let queue = try TaskQueue(at: repo.url.appending(path: ".git/queue.sqlite"))
        let log = try UsageLog(at: repo.url.appending(path: ".git/usage.sqlite"))
        try await log.record(task: "S2-08", usage: try #require(SessionUsage(output: UsageLogTests.stream(cost: 1, weekly: 0.2))),
                             started: Self.tuesday(9), ended: Self.tuesday(9, 30))
        try await queue.add(QueuedTask(id: "T9-01", goal: "One", doneMeans: "One"))
        let rules = BudgetRules(reserve: 0.9)
        let runner = QueueRunner(
            queue: queue,
            runner: ManualRunner(repository: repo.url, session: try repo.script("session", RollbackTests.session), tests: ["true"]),
            budget: Budget(rules: rules, log: log, calendar: Self.calendar, now: { Self.tuesday(10) })
        )

        let run = try await runner.run()

        #expect(run.outcomes.isEmpty)
        #expect(run.paused == "Keeping the reserve: 20% of the week is used, the next task needs about 3%, and 90% is kept back.")
        #expect(try await queue.task("T9-01")?.state == .queued)
        #expect(try await repo.git("branch", "--list", "task/*") == "")
    }

    @Test func roboticsHoursAreBlocked() {
        let rules = BudgetRules(blocked: [Self.robotics], reserve: 0.2)
        #expect(rules.decide(at: Self.tuesday(17), limits: Self.limits(weekly: 0.1), nextTask: 0.02, calendar: Self.calendar)
                == .pause("Robotics hours until 20:00."))
        #expect(rules.decide(at: Self.tuesday(20), limits: Self.limits(weekly: 0.1), nextTask: 0.02, calendar: Self.calendar) == .run)
        #expect(rules.decide(at: Self.tuesday(15, 59), limits: Self.limits(weekly: 0.1), nextTask: 0.02, calendar: Self.calendar) == .run)
        let wednesday = Self.tuesday(17).addingTimeInterval(86_400)
        #expect(rules.decide(at: wednesday, limits: Self.limits(weekly: 0.1), nextTask: 0.02, calendar: Self.calendar) == .run)
    }

    @Test func aTaskThatWouldCrossTheReserveWaits() {
        let rules = BudgetRules(reserve: 0.25)
        #expect(rules.decide(at: Self.tuesday(2), limits: Self.limits(weekly: 0.70), nextTask: 0.04, calendar: Self.calendar) == .run)
        #expect(rules.decide(at: Self.tuesday(2), limits: Self.limits(weekly: 0.72), nextTask: 0.04, calendar: Self.calendar)
                == .pause("Keeping the reserve: 72% of the week is used, the next task needs about 4%, and 25% is kept back."))
    }

    @Test func aFullFiveHourWindowWaitsForItsReset() {
        let rules = BudgetRules(reserve: 0.25)
        #expect(rules.decide(at: Self.tuesday(2), limits: Self.limits(weekly: 0.3, fiveHour: 0.97), nextTask: 0.02,
                             calendar: Self.calendar)
                == .pause("The five-hour limit is nearly full; it resets at 23:00."))
    }

    @Test func withNoLimitsKnownYetOnlyTheHoursAreChecked() {
        let rules = BudgetRules(blocked: [Self.robotics], reserve: 0.25)
        #expect(rules.decide(at: Self.tuesday(2), limits: nil, nextTask: 0.02, calendar: Self.calendar) == .run)
    }

    @Test func swiftStopsMidRunWhenTheNextTaskWouldCrossTheReserve() async throws {
        let repo = try await TempRepo()
        defer { repo.remove() }
        // Each session reports the week a little fuller than the last: 50%, then 53%.
        let session = """
        id=$(printf '%s' "$1" | grep -o 'Do task [A-Z0-9-]*' | cut -d' ' -f3)
        n=$(cat .git/count 2>/dev/null || echo 0); echo $((n + 1)) > .git/count
        echo "$id" > "$id.txt"; git add -A; git commit -q -m "$id: Add $id.txt"
        if [ "$n" = 0 ]; then weekly=0.5; else weekly=0.53; fi
        printf '%s\\n' '{"type":"rate_limit_event","rate_limit_info":{"unifiedWindows":{"five_hour":{"utilization":0.1,"resetsAt":1794625200},"seven_day":{"utilization":'$weekly',"resetsAt":1794693600}}}}'
        printf '%s\\n' '{"type":"result","total_cost_usd":1.0,"result":"Result: done\\nDid: It.","usage":{}}'
        """
        let queue = try TaskQueue(at: repo.url.appending(path: ".git/queue.sqlite"))
        let log = try UsageLog(at: repo.url.appending(path: ".git/usage.sqlite"))
        for id in ["T9-01", "T9-02", "T9-03"] { try await queue.add(QueuedTask(id: id, goal: id, doneMeans: id)) }
        let runner = QueueRunner(
            queue: queue,
            runner: ManualRunner(repository: repo.url, session: try repo.script("session", session), tests: ["true"]),
            usageLog: log,
            budget: Budget(rules: BudgetRules(reserve: 0.45), log: log, calendar: Self.calendar)
        )

        let run = try await runner.run()

        #expect(run.outcomes.map(\.task.id) == ["T9-01", "T9-02"])
        #expect(run.paused?.hasPrefix("Keeping the reserve: 53% of the week is used") == true)
        #expect(try await queue.task("T9-03")?.state == .queued)
    }
}
