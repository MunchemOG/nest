import Foundation

extension NestEvent {
    /// The `you.undo.asked` event for tapping Undo on `target`, or Redo when `target` is itself an undo.
    public static func undoAsked(target: NestEvent, at time: Date = .now, id: String? = nil) -> NestEvent {
        let verb = target.kind == .undo ? "redo" : "undo"
        return NestEvent(
            id: id ?? EventID.make(at: time),
            ts: time,
            sender: .you,
            kind: .ask,
            topic: .youUndoAsked,
            summary: summaryLimit("You asked to \(verb): \(target.summary)"),
            data: ["target": .string(target.id)],
            undo: nil,
            causedBy: nil,
            attention: .none
        )
    }

    /// The longest a summary may be.
    public static let summaryMaxLength = 90

    private static func summaryLimit(_ text: String) -> String {
        guard text.count > summaryMaxLength else { return text }
        return String(text.prefix(summaryMaxLength - 1)) + "…"
    }
}
