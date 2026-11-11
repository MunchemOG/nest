import Foundation

/// A fake flock that replays recorded events, waiting the real gap between them divided by `speed`.
public struct ReplaySource<C: Clock>: FlockSource where C.Duration == Duration {
    /// The events to replay, in order.
    public let recorded: [NestEvent]
    /// The clock that times the gaps.
    public let clock: C
    /// How many times faster than real time to replay; 60 plays a minute each second.
    public let speed: Double

    /// A replay of `events` timed by `clock` at `speed`, which must be above zero.
    public init(events: [NestEvent], clock: C, speed: Double) {
        precondition(speed > 0, "speed must be above zero")
        self.recorded = events
        self.clock = clock
        self.speed = speed
    }

    /// Replays every event, then finishes; stops early if the listener stops listening.
    public func events() -> AsyncStream<NestEvent> {
        let events = recorded
        let clock = clock
        let speed = speed
        return AsyncStream { continuation in
            let task = Task {
                var previous: Date?
                for event in events {
                    if let previous, event.ts > previous {
                        do {
                            try await clock.sleep(for: .seconds(event.ts.timeIntervalSince(previous) / speed))
                        } catch {
                            break
                        }
                    }
                    continuation.yield(event)
                    previous = event.ts
                }
                continuation.finish()
            }
            continuation.onTermination = { _ in task.cancel() }
        }
    }
}

extension ReplaySource {
    /// A replay of the bundled demo day.
    public static func demoDay(clock: C, speed: Double) throws -> ReplaySource {
        ReplaySource(events: try DemoDay.events(), clock: clock, speed: speed)
    }
}
