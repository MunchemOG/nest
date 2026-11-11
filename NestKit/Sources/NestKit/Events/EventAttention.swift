/// How far an event may reach you.
public enum EventAttention: String, CaseIterable, Hashable, Sendable, Decodable {
    /// The timeline only.
    case none
    /// Waits in the Inbox.
    case inbox
    /// Shown at the next calm moment.
    case calm
    /// Interrupts now.
    case ping
}
