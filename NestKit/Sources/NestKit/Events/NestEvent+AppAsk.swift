import Foundation

extension NestEvent {
    /// The `app.ask.sent` event for telling a bird (or `everyone`) something from the app.
    public static func appAsk(to recipient: String, text: String, at time: Date = .now, id: String? = nil) -> NestEvent {
        let name = Bird(rawValue: recipient)?.name ?? recipient.capitalized
        let summary = "Nest asked \(name): \(text)"
        return NestEvent(
            id: id ?? EventID.make(at: time),
            ts: time,
            sender: .app,
            kind: .ask,
            topic: .appAskSent,
            summary: summary.count > summaryMaxLength ? String(summary.prefix(summaryMaxLength - 1)) + "…" : summary,
            data: ["to": .string(recipient), "text": .string(text)],
            undo: nil,
            causedBy: nil,
            attention: .none
        )
    }
}
