import Foundation
import Testing
@testable import NestKit

struct SwiftReportTests {
    static let now = Date(timeIntervalSince1970: 1_794_640_000)

    static func ok(_ id: String, tests: Int) -> ReportedTask { ReportedTask(id: id, ending: .ok, testsAdded: tests) }

    /// Eleven tasks: nine merged, one held with a guess, one failed and rolled back with a guess.
    static let night: [ReportedTask] = [
        ok("S2-01", tests: 2), ok("S2-02", tests: 1), ok("S2-03", tests: 3), ok("S2-04", tests: 1), ok("S2-05", tests: 2),
        ReportedTask(id: "S2-06", ending: .held, testsAdded: 0,
                     why: "Undo test fails after Home tests", guess: "shared store", confidence: 0.7),
        ok("S2-07", tests: 2), ok("S2-08", tests: 1), ok("S2-09", tests: 2),
        ReportedTask(id: "S2-10", ending: .fail, testsAdded: 0, why: "Home broke after the merge", guess: "a stale snapshot",
                     confidence: 0.6),
        ok("S2-11", tests: 0),
    ]

    static func usage(weekly: Double = 0.38) -> ReportedUsage {
        ReportedUsage(weekly: weekly, fiveHour: 0.4, costUSD: 18.5, reserve: 0.25)
    }

    @Test func aFixtureRunOfElevenTasksYieldsTheExpectedStatusHeadlineAndThreePoints() throws {
        let report = SwiftReport(tasks: Self.night, testsPassing: 212, healthy: true, usage: Self.usage(),
                                 highlight: "The Timeline can undo.")
        #expect(report.status == .green)
        #expect(report.health == "Nest is healthy · 212 tests passing")
        #expect(report.headline == "9 of 11 tasks merged. The Timeline can undo.")
        #expect(report.tasks == ["ok", "ok", "ok", "ok", "ok", "held", "ok", "ok", "ok", "fail", "ok"])
        #expect(report.points == [
            ReportPoint(figure: "+14", text: "new tests; the safety net is now 212."),
            ReportPoint(figure: "38%", text: "of the weekly limit used. Your robotics reserve is untouched."),
            ReportPoint(figure: "1 held", text: "Undo test fails after Home tests. Best guess: shared store, 70%."),
        ])

        let event = report.event(at: Self.now)
        #expect(event.topic == .swiftReportReady)
        #expect(event.kind == .report)
        #expect(event.sender == .bird(.swift))
        #expect(event.undo == nil)
        #expect(event.summary == "Swift: Green. 9 of 11 tasks merged. The Timeline can undo.")
        #expect(event.data["status"] == .string("green"))
        #expect(event.data["headline"] == .string(report.headline))
        #expect(event.data["points"] == .array([
            .object(["figure": .string("+14"), "text": .string("new tests; the safety net is now 212.")]),
            .object(["figure": .string("38%"), "text": .string("of the weekly limit used. Your robotics reserve is untouched.")]),
            .object(["figure": .string("1 held"), "text": .string("Undo test fails after Home tests. Best guess: shared store, 70%.")]),
        ]))
        #expect(event.data["usage"] == .object(["weekly": .number(0.38), "five_hour": .number(0.4), "cost_usd": .number(18.5)]))
        #expect(event.attention == .calm)
    }

    @Test func aFailureSwiftCannotExplainIsAmber() {
        let tasks = [Self.ok("T-01", tests: 1), ReportedTask(id: "T-02", ending: .fail, testsAdded: 0, why: "Home broke")]
        let report = SwiftReport(tasks: tasks, testsPassing: 50, healthy: true, usage: Self.usage())
        #expect(report.status == .amber)
        #expect(report.points.last == ReportPoint(figure: "1 failed", text: "Home broke. No guess yet."))
    }

    @Test func usageCloseToTheReserveIsAmber() {
        let report = SwiftReport(tasks: [Self.ok("T-01", tests: 1)], testsPassing: 50, healthy: true, usage: Self.usage(weekly: 0.72))
        #expect(report.status == .amber)
        #expect(report.points[1] == ReportPoint(figure: "72%", text: "of the weekly limit used. 3% left before the reserve."))
    }

    @Test func aBrokenNestIsRedAndPings() {
        let report = SwiftReport(tasks: [Self.ok("T-01", tests: 1)], testsPassing: 49, healthy: false, usage: Self.usage())
        #expect(report.status == .red)
        #expect(report.health == "Nest is broken · 49 tests passing")
        #expect(report.event(at: Self.now).attention == .ping)
    }

    @Test func aQuietNightSaysNothingWasHeld() {
        let report = SwiftReport(tasks: [Self.ok("T-01", tests: 0)], testsPassing: 50, healthy: true, usage: Self.usage())
        #expect(report.headline == "1 of 1 task merged.")
        #expect(report.points.count == 3)
        #expect(report.points[2] == ReportPoint(figure: "0 held", text: "Nothing was held or rolled back."))
    }
}
