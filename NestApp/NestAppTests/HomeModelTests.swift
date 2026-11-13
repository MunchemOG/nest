import Foundation
import SwiftUI
import NestKit
import Testing
@testable import NestApp

@MainActor
struct HomeModelTests {
    /// Waits, without sleeping, until `condition` holds or the attempts run out.
    static func eventually(_ condition: () -> Bool) async -> Bool {
        for _ in 0..<1_000 {
            if condition() { return true }
            await Task.yield()
        }
        return condition()
    }

    @Test func withTheDemoDayReplayingANewEventAppearsLive() async throws {
        let events = try DemoDay.events()
        let (stream, feed) = AsyncStream<NestEvent>.makeStream()
        let model = HomeModel()
        let listening = Task { await model.listen(to: StreamSource(stream: stream)) }
        defer { listening.cancel() }
        for event in events.prefix(10) { feed.yield(event) }
        #expect(await Self.eventually { model.events.count == 10 })
        #expect(model.feed.first?.id == events[9].id)
        feed.yield(events[10])
        #expect(await Self.eventually { model.feed.first?.id == events[10].id })
        #expect(model.events.count == 11)
    }

    @Test func theFeedIsNewestFirstAndShort() throws {
        let model = HomeModel()
        let events = try DemoDay.events()
        events.forEach(model.receive)
        #expect(model.feed.count == HomeModel.feedLength)
        #expect(model.feed.map(\.id) == events.suffix(HomeModel.feedLength).reversed().map(\.id))
    }

    @Test func whatYouPublishLandsOnTheTimeline() throws {
        let model = HomeModel()
        let merge = try #require(try DemoDay.events().first { $0.topic == .swiftTaskMerged })
        model.receive(merge)
        model.publish(.undoAsked(target: merge))
        #expect(model.feed.first?.topic == .youUndoAsked)
    }

    @Test func undoneActionsAreKnown() throws {
        let model = HomeModel()
        try DemoDay.events().forEach(model.receive)
        let merged = try #require(model.events.first { $0.summary == "Swift merged N1-14 with 9 new tests" })
        #expect(model.isUndone(merged))
    }

    @Test func afterTheDemoDayTheKitAndTheReportNeedYou() throws {
        let model = HomeModel()
        try DemoDay.events().forEach(model.receive)
        #expect(model.needsYou.map(\.topic) == [.peacockKitReady, .swiftReportReady])
    }

    @Test func anAnsweredPitchNoLongerNeedsYou() throws {
        let model = HomeModel()
        let events = try DemoDay.events()
        let pitch = try #require(events.firstIndex { $0.topic == .crowPitchMade })
        events[...pitch].forEach(model.receive)
        #expect(model.needsYou.first?.topic == .crowPitchMade)
        events[(pitch + 1)...].forEach(model.receive)
        #expect(!model.needsYou.contains { $0.topic == .crowPitchMade })
    }

    @Test func theHeadlineFollowsTheDay() throws {
        let events = try DemoDay.events()
        func headline(after summary: String) throws -> Headline {
            let model = HomeModel()
            let index = try #require(events.firstIndex { $0.summary == summary })
            events[...index].forEach(model.receive)
            return model.headline
        }
        #expect(try headline(after: "Swift started a night run on three tasks").main == "Swift is building N1-13.")
        #expect(try headline(after: "Swift finished the night run: two merged, one held").main == "All six are idle.")
        #expect(try headline(after: "Owl saw Mithun settle into flow").main == "You've been in flow for 0 min.")
        #expect(try headline(after: "Owl saw Mithun leave for lunch").main == "You're away.")
        #expect(try headline(after: "Wren switched to Focus mode until 15:30").main == "Wren is holding focus until 15:30.")
        let night = try headline(after: "Swift started a night run on N1-14 and N1-15")
        #expect(night.main == "Swift is building N1-14.")
        #expect(night.sub == "You're away.")
    }

    @Test func theDemoDayHomeMatchesItsSnapshot() throws {
        let model = HomeModel()
        try DemoDay.events().forEach(model.receive)
        let home = HomeScreen(model: model)
            .environment(\.timeZone, TimeZone(identifier: "America/Chicago")!)
            .frame(width: NestSpace.s10 * 9, height: NestSpace.s10 * 6)
        try Snapshot.expect(home, named: "home-demo-day", rendering: .window)
    }

    @Test func tagLinesSayWhatEachBirdIsUpTo() throws {
        let model = HomeModel()
        let events = try DemoDay.events()
        let chicago = TimeZone(identifier: "America/Chicago")!
        let (past, _) = DemoReplayStart.split(events, at: "15:16", in: chicago)
        past.forEach(model.receive)
        model.advanceClock(to: try #require(DemoReplayStart.start(events, at: "15:16", in: chicago)))
        #expect(model.tagLine(for: .wren) == "Focus until 15:30")
        #expect(model.tagLine(for: .crow) == "Paused for Focus")
        #expect(model.tagLine(for: .owl) == "In flow 1 h 35 min")
        #expect(model.headline.sub.hasPrefix("You've been in flow for 1 h 35 min."))
    }

    @Test func theHeadlineCountsWhatNeedsYou() {
        #expect(Headline.attention(count: 0) == nil)
        #expect(Headline.attention(count: 1) == "One thing needs you")
        #expect(Headline.attention(count: 2) == "Two things need you")
        #expect(Headline.attention(count: 5) == "5 things need you")
    }
}

/// A source that hands on whatever is yielded to its stream.
struct StreamSource: FlockSource {
    let stream: AsyncStream<NestEvent>
    func events() -> AsyncStream<NestEvent> { stream }
}
