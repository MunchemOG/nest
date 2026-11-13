import Foundation
import NestKit
import Testing
@testable import NestApp

@MainActor
struct HomeControlsTests {
    static let chicago = TimeZone(identifier: "America/Chicago")!

    @Test func aCommandGoesToTheBirdNamedAtItsStart() {
        #expect(CommandText.parse("Swift, build N1-15", picked: nil) == ("swift", "build N1-15"))
        #expect(CommandText.parse("wren tidy Downloads", picked: .owl) == ("wren", "tidy Downloads"))
    }

    @Test func otherwiseToThePickedBirdOrEveryone() {
        #expect(CommandText.parse("tidy Downloads", picked: .wren) == ("wren", "tidy Downloads"))
        #expect(CommandText.parse("focus mode for two hours", picked: nil) == ("everyone", "focus mode for two hours"))
    }

    @Test func sendingPublishesAnAsk() throws {
        let model = HomeModel()
        model.send("Swift, build N1-15", to: nil)
        let ask = try #require(model.events.last)
        #expect(ask.topic == .appAskSent)
        #expect(ask.data["to"] == .string("swift"))
        #expect(ask.data["text"] == .string("build N1-15"))
    }

    @Test func switchingModeAsksWren() throws {
        let model = HomeModel()
        model.switchMode(to: "Night")
        #expect(try #require(model.events.last).data == ["to": .string("wren"), "text": .string("Night mode")])
    }

    @Test func aPitchCardAnswersCrowAndGoesAway() throws {
        let model = HomeModel()
        let events = try DemoDay.events()
        let pitch = try #require(events.firstIndex { $0.topic == .crowPitchMade })
        events[...pitch].forEach(model.receive)
        let card = try #require(model.needsYou.first)
        let build = try #require(NeedsYouAction.actions(for: card).first)
        #expect(build.title == "Build it")
        model.answer(card, with: build)
        #expect(!model.needsYou.contains(card))
        #expect(model.events.last?.data == ["to": .string("crow"), "text": .string("Build it")])
    }

    @Test func aReportCardIsPutAwayWithoutTellingAnyone() throws {
        let model = HomeModel()
        let events = try DemoDay.events()
        let report = try #require(events.firstIndex { $0.topic == .swiftReportReady })
        events[...report].forEach(model.receive)
        let card = try #require(model.needsYou.first)
        let count = model.events.count
        model.answer(card, with: try #require(NeedsYouAction.actions(for: card).first))
        #expect(model.events.count == count)
        #expect(model.needsYou.isEmpty)
    }

    @Test func focusProgressRunsFromTheSwitchToTheEndTime() throws {
        let events = try DemoDay.events()
        let focus = try #require(events.first { $0.summary == "Wren switched to Focus mode until 15:30" })
        let progress = try #require(FocusProgress(since: focus.ts, until: "15:30", now: focus.ts.addingTimeInterval(60 * 60), timeZone: Self.chicago))
        #expect(abs(progress.fraction - 0.5) < 0.01)
        #expect(progress.minutesLeft == 60)
        #expect(FocusProgress(since: focus.ts, until: "soon", now: focus.ts, timeZone: Self.chicago) == nil)
    }

    @Test func compactRowsDropTheBirdsName() throws {
        let event = try #require(try DemoDay.events().first { $0.summary == "Owl saw Mithun sit down" })
        #expect(ActivityRow(event, isUndone: false, isCompact: true) { _ in }.sentence == "Saw Mithun sit down")
        #expect(ActivityRow(event, isUndone: false) { _ in }.sentence == "Owl saw Mithun sit down")
    }

    @Test func theReplayCanStartPartWayThroughTheDay() throws {
        let events = try DemoDay.events()
        let (past, future) = DemoReplayStart.split(events, at: "15:16", in: Self.chicago)
        #expect(past.count + future.count == events.count)
        #expect(past.last?.summary == "Owl saw Mithun's flow end" || past.last.map { $0.ts < future.first!.ts } == true)
        #expect(DemoReplayStart.split(events, at: nil, in: Self.chicago).past.isEmpty)
    }

    @Test func theStudioGetsThePrototypesStatuses() throws {
        let model = HomeModel()
        let events = try DemoDay.events()
        let (past, _) = DemoReplayStart.split(events, at: "15:16", in: Self.chicago)
        past.forEach(model.receive)
        let state = model.studioState
        #expect(state.statuses["wren"] == "working")
        #expect(state.statuses["crow"] == "paused")
        #expect(state.statuses["owl"] == "idle")
        #expect(state.tagLines["crow"] == "Paused for Focus")
        #expect(state.mode == "Focus")
        #expect(state.until == "15:30")
        #expect(state.script.contains("\"until\":\"15:30\""))
    }
}
