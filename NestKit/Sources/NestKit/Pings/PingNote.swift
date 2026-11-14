/// A notification that interrupts you: a title and one line.
public struct PingNote: Sendable, Equatable {
    /// The title, such as "Swift: Red".
    public let title: String
    /// The line under it.
    public let body: String

    /// A notification with the given title and body.
    public init(title: String, body: String) {
        self.title = title
        self.body = body
    }
}
