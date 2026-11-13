import Foundation

/// What you are typing in the composer.
struct ChatDraft: Hashable, Sendable {
    var text = ""

    /// The text as it would be sent.
    var trimmed: String { text.trimmingCharacters(in: .whitespacesAndNewlines) }

    /// Whether there is anything to send.
    var canSend: Bool { !trimmed.isEmpty }

    /// Returns the trimmed text and clears the draft; nil when there is nothing to send.
    mutating func send() -> String? {
        guard canSend else { return nil }
        defer { text = "" }
        return trimmed
    }
}
