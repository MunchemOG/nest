/// Who published an event: one of the birds, you, or the app.
public enum EventSender: Hashable, Sendable, Decodable {
    /// One of the six birds.
    case bird(Bird)
    /// You, through an undo or a correction.
    case you
    /// The Nest app itself.
    case app

    /// The sender named by an event's `bird` field, or nil if the contract has no such sender.
    public init?(rawValue: String) {
        switch rawValue {
        case "you": self = .you
        case "app": self = .app
        default:
            guard let bird = Bird(rawValue: rawValue) else { return nil }
            self = .bird(bird)
        }
    }

    /// The sender as it is written in an event's `bird` field.
    public var rawValue: String {
        switch self {
        case .bird(let bird): bird.rawValue
        case .you: "you"
        case .app: "app"
        }
    }

    /// Decodes a sender from its name, throwing on a name the contract doesn't list.
    public init(from decoder: any Decoder) throws {
        let container = try decoder.singleValueContainer()
        let raw = try container.decode(String.self)
        guard let sender = EventSender(rawValue: raw) else {
            throw DecodingError.dataCorruptedError(in: container, debugDescription: "Unknown sender \(raw)")
        }
        self = sender
    }
}
