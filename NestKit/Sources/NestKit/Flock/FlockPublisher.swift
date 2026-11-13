/// Where the app sends its own events (asks, undo requests) onto the bus.
public protocol FlockPublisher: Sendable {
    /// Puts `event` on the bus.
    func publish(_ event: NestEvent) async
}
