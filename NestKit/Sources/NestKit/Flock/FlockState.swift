/// Each bird's state, built by applying events in the order they arrive.
public struct FlockState: Hashable, Sendable {
    private var birds: [Bird: BirdState] = [:]

    /// A flock nothing has been heard from.
    public init() {}

    /// The state after applying `events` in order.
    public init(events: some Sequence<NestEvent>) {
        for event in events {
            apply(event)
        }
    }

    /// One bird's state.
    public subscript(bird: Bird) -> BirdState {
        birds[bird] ?? BirdState()
    }

    /// Updates the state with one more event.
    public mutating func apply(_ event: NestEvent) {
        switch event.topic {
        case .appBirdPaused, .appBirdResumed:
            guard case .string(let raw) = event.data["bird"], let bird = Bird(rawValue: raw) else { return }
            birds[bird, default: BirdState()].isPaused = event.topic == .appBirdPaused
        default:
            break
        }
        guard case .bird(let bird) = event.sender else { return }
        var state = self[bird]
        state.lastHeard = event.ts
        state.doing = event.summary
        if [.action, .undo, .note].contains(event.kind) {
            state.latestAction = event
        }
        birds[bird] = state
    }
}
