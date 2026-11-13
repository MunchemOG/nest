import Foundation
import NestKit
import Observation

/// Everything Home shows, built live from the events it hears.
@Observable
@MainActor
final class HomeModel {
    /// How many rows the activity feed shows.
    static let feedLength = 5

    /// Each bird's state and reactions.
    let flock = FlockModel()
    /// Every event heard, oldest first.
    private(set) var events: [NestEvent] = []
    private(set) var facts = HeadlineFacts()
    private var ledger = UndoLedger(events: [])
    private var dismissed: Set<String> = []

    private var clock: Date?

    /// The time Home shows and measures from: the replay's clock, or the newest event's time if that is later.
    var now: Date? {
        switch (clock, events.last?.ts) {
        case let (clock?, latest?): max(clock, latest)
        case let (clock, latest): clock ?? latest
        }
    }

    /// Moves Home's clock on, for a replay whose time runs faster than the wall clock.
    func advanceClock(to time: Date) {
        clock = time
    }

    /// The newest events, newest first.
    var feed: [NestEvent] { Array(events.suffix(Self.feedLength).reversed()) }

    /// Pitches, reports and kits that asked for you and haven't been answered, newest first.
    var needsYou: [NestEvent] {
        let answered = Set(events.filter { $0.topic == .crowPitchAnswered }.compactMap { $0.data["pitch"]?.string })
        return events
            .filter { $0.attention != .none && [.pitch, .report].contains($0.kind) }
            .filter { !answered.contains($0.id) && !dismissed.contains($0.id) }
            .reversed()
    }

    /// The statement at the top of Home.
    var headline: Headline { Headline(facts: facts, waiting: needsYou.count, now: now) }

    /// The short line under a bird's tile in the scene, from what the app knows about it.
    func tagLine(for bird: Bird) -> String {
        let status = flock.status(of: bird)
        if status == .paused { return facts.mode == "Focus" ? "Paused for Focus" : "Paused" }
        switch bird {
        case .wren:
            if let until = facts.focusUntil { return "Focus until \(until)" }
            if let mode = facts.mode { return "\(mode) mode" }
        case .owl:
            if facts.inFlow, let since = facts.flowSince, let now { return "In flow \(Headline.duration(now.timeIntervalSince(since)))" }
            if facts.presence == "away" { return "You're away" }
        case .swift:
            if let task = facts.building { return "Building \(task)" }
        case .magpie:
            let notes = events.filter { $0.sender == .bird(.magpie) && $0.kind == .note }.count
            if notes > 0 { return notes == 1 ? "1 note today" : "\(notes) notes today" }
        case .crow, .peacock:
            break
        }
        return StatusPillKind.bird(bird, status).word
    }

    /// Applies one event.
    func receive(_ event: NestEvent) {
        events.append(event)
        flock.receive(event)
        facts.apply(event)
        ledger = UndoLedger(events: events)
    }

    /// Whether `event` is currently reversed.
    func isUndone(_ event: NestEvent) -> Bool {
        ledger.isUndone(event.id)
    }

    /// Puts one of your own events on the timeline. Until the bus exists, it goes straight to Home.
    func publish(_ event: NestEvent) {
        receive(event)
    }

    /// Answers a card in the needs-you stack: tells its bird, if the answer is for a bird, and puts the card away.
    func answer(_ event: NestEvent, with action: NeedsYouAction) {
        if action.tellsTheBird, let bird = event.sender.bird {
            publish(.appAsk(to: bird.rawValue, text: action.title))
        }
        dismissed.insert(event.id)
    }

    /// Sends what you typed in the command bar to `bird`, the bird named at its start, or everyone.
    func send(_ text: String, to bird: Bird?) {
        let (recipient, words) = CommandText.parse(text, picked: bird)
        guard !words.isEmpty else { return }
        publish(.appAsk(to: recipient, text: words))
    }

    /// Asks Wren to switch to a mode.
    func switchMode(to mode: String) {
        publish(.appAsk(to: Bird.wren.rawValue, text: "\(mode) mode"))
    }

    /// Hears every event from `source` until it finishes.
    func listen(to source: some FlockSource) async {
        for await event in source.events() {
            receive(event)
        }
    }
}
