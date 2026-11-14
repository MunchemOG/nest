import Foundation
import NestKit
import Testing
@testable import NestApp

@MainActor
struct ReportDetailsTests {
    @Test func readsTheReportSwiftBuilds() throws {
        let tasks = [ReportedTask(id: "T-01", ending: .ok, testsAdded: 3),
                     ReportedTask(id: "T-02", ending: .held, testsAdded: 0, why: "Timed out", guess: "the real clock", confidence: 0.6)]
        let event = SwiftReport(tasks: tasks, testsPassing: 212, healthy: true,
                                usage: ReportedUsage(weekly: 0.38, fiveHour: 0.2, costUSD: 4, reserve: 0.25)).event()
        let details = try #require(ReportDetails(event))
        #expect(details.status == .green)
        #expect(details.health == "Nest is healthy · 212 tests passing")
        #expect(details.headline == "1 of 2 tasks merged.")
        #expect(details.tasks == [.ok, .held])
        #expect(details.points.map(\.figure) == ["+3", "38%", "1 held"])
        #expect(details.points.last?.text == "Timed out. Best guess: the real clock, 60%.")
    }

    @Test func readsTheDemoDaysOlderReportShape() throws {
        let report = try #require(try DemoDay.events().first { $0.topic == .swiftReportReady })
        let details = try #require(ReportDetails(report))
        #expect(details.status == .amber)
        #expect(details.headline == "Two merged, one held")
        #expect(details.points.map(\.text) == ["N1-13 merged", "N1-14 merged", "N1-15 held: the replay test timed out"])
        #expect(details.points.allSatisfy { $0.figure.isEmpty })
        #expect(details.health == nil)
    }

    @Test func onlySwiftsReportsHaveDetails() throws {
        let pitch = try #require(try DemoDay.events().first { $0.kind == .pitch })
        #expect(ReportDetails(pitch) == nil)
    }

    @Test func eachStatusAndEndingHasItsOwnToken() {
        #expect(ReportDetails.color(for: .green) == .statusSuccess)
        #expect(ReportDetails.color(for: .amber) == .statusWarning)
        #expect(ReportDetails.color(for: .red) == .statusDanger)
        #expect(ReportDetails.color(for: TaskEnding.ok) == .statusSuccess)
        #expect(ReportDetails.color(for: TaskEnding.held) == .statusWarning)
        #expect(ReportDetails.color(for: TaskEnding.fail) == .statusDanger)
    }
}
