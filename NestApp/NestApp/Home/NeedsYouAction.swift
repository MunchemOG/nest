import NestKit

/// A button on a needs-you card.
struct NeedsYouAction: Hashable, Sendable {
    let title: String
    /// Whether pressing it tells the bird (an answer to a pitch) rather than only putting the card away.
    let tellsTheBird: Bool
    /// Whether pressing it opens the bird's close-up and leaves the card where it is.
    var opensTheBird = false

    /// The buttons for a card, the main one first.
    static func actions(for event: NestEvent) -> [NeedsYouAction] {
        if event.kind == .pitch {
            return ["Build it", "Later", "No"].map { NeedsYouAction(title: $0, tellsTheBird: true) }
        }
        if event.topic == .swiftReportReady {
            return [NeedsYouAction(title: "Got it", tellsTheBird: false),
                    NeedsYouAction(title: "Open Swift", tellsTheBird: false, opensTheBird: true)]
        }
        return [NeedsYouAction(title: "Got it", tellsTheBird: false)]
    }
}
