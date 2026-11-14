/// Sends a notification only for events whose `attention` is `ping`, and only once per event.
/// Everything else waits for the Inbox or a calm moment (see `docs/event-bus.md`).
public actor CriticalPings {
    private let send: @Sendable (PingNote) async -> Void
    private var sent: Set<String> = []

    /// A policy that sends its notifications with `send`.
    public init(send: @escaping @Sendable (PingNote) async -> Void) {
        self.send = send
    }

    /// Hears one event and pings you if it must.
    public func receive(_ event: NestEvent) async {
        guard event.attention == .ping, sent.insert(event.id).inserted else { return }
        await send(Self.note(for: event))
    }

    /// The notification for `event`: a report's status and headline with its health, or the event's own sentence.
    static func note(for event: NestEvent) -> PingNote {
        guard event.topic == .swiftReportReady, case .string(let status)? = event.data["status"],
              case .string(let headline)? = event.data["headline"] else {
            let title = switch event.sender {
            case .bird(let bird): bird.name
            case .you: "You"
            case .app: "Nest"
            }
            return PingNote(title: title, body: event.summary)
        }
        let health = if case .string(let health)? = event.data["health"] { " \(health)" } else { "" }
        return PingNote(title: "Swift: \(status.capitalized)", body: headline + health)
    }
}
