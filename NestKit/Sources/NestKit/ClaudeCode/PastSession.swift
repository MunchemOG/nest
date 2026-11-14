import Foundation

/// A Claude Code session from a project's history, whether it ran in Swift or in the terminal.
public struct PastSession: Sendable, Equatable, Identifiable {
    /// The session's id, for resuming it.
    public let id: String
    /// Claude Code's summary of it, or your first message.
    public let title: String
    /// When you last wrote in it.
    public let lastActive: Date
    /// How many messages you sent.
    public let messages: Int
}
