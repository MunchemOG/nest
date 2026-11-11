/// Where the app hears the flock's events from.
public protocol FlockSource: Sendable {
    /// The events, oldest first; each call starts a new stream for one listener.
    func events() -> AsyncStream<NestEvent>
}
