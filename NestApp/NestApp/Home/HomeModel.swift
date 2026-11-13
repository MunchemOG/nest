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

    /// The newest events, newest first.
    var feed: [NestEvent] { Array(events.suffix(Self.feedLength).reversed()) }

    /// Pitches, reports and kits that asked for you and haven't been answered, newest first.
    var needsYou: [NestEvent] {
        let answered = Set(events.filter { $0.topic == .crowPitchAnswered }.compactMap { $0.data["pitch"]?.string })
        return events
            .filter { $0.attention != .none && [.pitch, .report].contains($0.kind) }
            .filter { !answered.contains($0.id) }
            .reversed()
    }

    /// The statement at the top of Home.
    var headline: Headline { Headline(facts: facts, waiting: needsYou.count) }

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

    /// Hears every event from `source` until it finishes.
    func listen(to source: some FlockSource) async {
        for await event in source.events() {
            receive(event)
        }
    }
}
