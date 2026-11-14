/// What a chat message to Swift asks for.
public enum SwiftChatAsk: Sendable, Equatable {
    /// A task to queue, with its test.
    case task(goal: String, doneMeans: String)
    /// A task with no test yet; Swift asks for one before queueing it.
    case needsTest(goal: String)
}
