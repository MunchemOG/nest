import Foundation
import NestKit
import SwiftUI
import Testing
@testable import NestApp

@MainActor
struct TimelineTests {
    static let chicago = TimeZone(identifier: "America/Chicago")!
    static let events = (try? DemoDay.events()) ?? []

    static func rows(_ query: TimelineQuery) -> [NestEvent] {
        TimelineQuery.groups(Self.events, matching: query, in: Self.chicago).flatMap(\.events)
    }

    @Test(arguments: Bird.allCases)
    func filteringToOneBirdShowsOnlyItsRows(_ bird: Bird) {
        let rows = Self.rows(TimelineQuery(bird: bird))
        #expect(!rows.isEmpty)
        #expect(rows.allSatisfy { $0.sender == .bird(bird) })
        #expect(rows.count == Self.events.filter { $0.sender == .bird(bird) }.count)
    }

    @Test func searchFindsAFileName() {
        let rows = Self.rows(TimelineQuery(text: "match-sheet-q13"))
        #expect(rows.map(\.summary) == ["Magpie linked the scouting sheets to the Regionals note", "Wren moved match-sheet-q13.csv to Robotics / Scouting"])
    }

    @Test func searchLooksInsideEventDetails() {
        let rows = Self.rows(TimelineQuery(text: "regionals.md"))
        #expect(rows.contains { $0.summary == "Wren reopened the Robotics workspace: 4 files, 6 tabs" })
    }

    @Test func searchAndFilterCombine() {
        let rows = Self.rows(TimelineQuery(bird: .magpie, text: "match-sheet-q13"))
        #expect(rows.map(\.sender) == [.bird(.magpie)])
    }

    @Test func anEmptyQueryShowsEverythingNewestFirst() {
        let rows = Self.rows(TimelineQuery())
        #expect(rows.count == Self.events.count)
        #expect(rows.first?.id == Self.events.last?.id)
    }

    @Test func eventsAreGroupedByDay() throws {
        let first = try #require(Self.events.first)
        let nextDay = NestEvent(
            id: "evt_next", ts: first.ts.addingTimeInterval(86_400), sender: .bird(.owl), kind: .signal,
            topic: .owlPresenceChanged, summary: "Owl saw Mithun sit down", data: [:], undo: nil, causedBy: nil, attention: .none
        )
        let groups = TimelineQuery.groups([first, nextDay], matching: TimelineQuery(), in: Self.chicago)
        #expect(groups.count == 2)
        #expect(groups.first?.events.map(\.id) == ["evt_next"])
        #expect(groups.map { $0.title(locale: Locale(identifier: "en_US")) } == ["Wednesday, November 11", "Tuesday, November 10"])
    }

    @Test func theFilteredTimelineMatchesItsSnapshot() throws {
        let model = HomeModel()
        Self.events.forEach(model.receive)
        let screen = TimelineScreen(model: model, query: TimelineQuery(bird: .wren, text: "robotics"))
            .environment(\.timeZone, Self.chicago)
            .environment(\.locale, Locale(identifier: "en_US"))
            .frame(width: NestSpace.s10 * 6, height: NestSpace.s10 * 6)
        try Snapshot.expect(screen, named: "timeline-wren-robotics", rendering: .window)
    }
}
