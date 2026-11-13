/// One line in a chat with the flock.
struct ChatMessage: Identifiable, Hashable, Sendable {
    let id: String
    let sender: ChatSender
    let text: String
}
