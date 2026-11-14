import Foundation
import Testing
@testable import NestKit

struct RunReportTests {
    static let usage = ReportedUsage(weekly: 0.3, fiveHour: 0.4, costUSD: 2.5, reserve: 0.25)

    static func outcome(_ id: String, tests: String?, held: String? = nil) -> RunOutcome {
        let summary = tests.flatMap { SummaryBlock(in: "Result: \(held == nil ? "done" : "held")\nDid: It.\nTests: \($0)\n") }
        return RunOutcome(task: QueueTask(id: id, goal: id, doneMeans: id, needs: ""), branch: "task/\(id)",
                          summary: summary, testsPassed: held == nil, held: held)
    }

    @Test func eachTaskEndsAsTheQueueLeftIt() {
        let run = QueueRun(outcomes: [
            Self.outcome("T9-01", tests: "10/10, 2 new"),
            Self.outcome("T9-02", tests: "11/11, 1 new"),
            Self.outcome("T9-03", tests: nil, held: "the suite failed when the runner ran it"),
        ], paused: nil)

        let report = SwiftReport(run: run, states: ["T9-01": .done, "T9-02": .held, "T9-03": .held], usage: Self.usage)

        #expect(report.tasks == ["ok", "fail", "held"])
        #expect(report.headline == "1 of 3 tasks merged.")
        #expect(report.health == "Nest is healthy · 10 tests passing")
        #expect(report.points[0] == ReportPoint(figure: "+2", text: "new tests; the safety net is now 10."))
        #expect(report.points[2] == ReportPoint(figure: "1 held",
                                               text: "T9-03 was held: the suite failed when the runner ran it. No guess yet."))
        #expect(report.usage == Self.usage)
    }

    @Test func aRolledBackTaskSaysWhy() {
        let run = QueueRun(outcomes: [Self.outcome("T9-01", tests: "10/10, 2 new")], paused: nil)

        let report = SwiftReport(run: run, states: ["T9-01": .held], usage: Self.usage)

        #expect(report.tasks == ["fail"])
        #expect(report.points[0].figure == "+0")
        #expect(report.points[2] == ReportPoint(figure: "1 failed",
                                               text: "T9-01 was rolled back: the whole suite failed on main after the merge. No guess yet."))
    }
}
