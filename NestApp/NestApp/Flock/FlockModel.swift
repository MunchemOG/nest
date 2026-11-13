import Foundation
import NestKit
import Observation

/// The app's live view of the flock: each bird's state, and how many times each bird has acted.
@Observable
@MainActor
final class FlockModel {
    /// Each bird's state, from every event heard so far.
    private(set) var state = FlockState()
    /// The time of the newest event heard: "now" for a replay.
    private(set) var latest: Date?
    private var actionCounts: [Bird: Int] = [:]

    /// Applies one event; an action, undo or note from a bird makes that bird react once.
    func receive(_ event: NestEvent) {
        state.apply(event)
        latest = max(latest ?? event.ts, event.ts)
        if case .bird(let bird) = event.sender, [.action, .undo, .note].contains(event.kind) {
            actionCounts[bird, default: 0] += 1
        }
    }

    /// How many times `bird` has reacted; each change is one reaction.
    func reactions(of bird: Bird) -> Int {
        actionCounts[bird] ?? 0
    }

    /// The bird's status at the newest event's time.
    func status(of bird: Bird) -> BirdStatus {
        state[bird].status(at: latest ?? .distantPast)
    }

    /// Hears every event from `source` until it finishes.
    func listen(to source: some FlockSource) async {
        for await event in source.events() {
            receive(event)
        }
    }
}
