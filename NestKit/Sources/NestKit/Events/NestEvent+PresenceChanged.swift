import Foundation

extension NestEvent {
    /// The `owl.presence.changed` signal: presence went from `was` to `to` (`here`, `away`, `stranger` or `guest`).
    /// Until Owl exists, the app's menu bar switch publishes it in Owl's name.
    public static func presenceChanged(to: String, was: String, at time: Date = .now) -> NestEvent {
        let summary = switch to {
        case "here": "Owl saw you arrive"
        case "away": "Owl saw you leave"
        case "guest": "Owl saw a guest join you"
        default: "Owl saw someone it does not know"
        }
        return NestEvent(
            id: EventID.make(at: time), ts: time, sender: .bird(.owl), kind: .signal, topic: .owlPresenceChanged,
            summary: summary, data: ["to": .string(to), "was": .string(was)], undo: nil, causedBy: nil, attention: .none
        )
    }
}
