import Foundation

/// One event on the bus, decoded from the envelope in `docs/event-bus.md`.
public struct NestEvent: Hashable, Sendable, Decodable {
    /// `evt_` and a ULID, so ids sort by time.
    public let id: String
    /// When it happened.
    public let ts: Date
    /// Who published it (the `bird` field).
    public let sender: EventSender
    /// Which of the seven kinds it is.
    public let kind: EventKind
    /// What happened, as `<bird>.<thing>.<what happened>`.
    public let topic: EventTopic
    /// The one sentence the Timeline shows.
    public let summary: String
    /// Details for the topic.
    public let data: [String: JSONValue]
    /// How to reverse it, or nil if nothing changed.
    public let undo: EventUndo?
    /// The id of the event that led to this one.
    public let causedBy: String?
    /// How far it may reach you.
    public let attention: EventAttention

    enum CodingKeys: String, CodingKey {
        case id, ts, kind, topic, summary, data, undo, attention
        case sender = "bird"
        case causedBy = "caused_by"
    }

    /// Decodes an event, throwing on a missing field, an unlisted sender, kind or attention, or a time without an offset.
    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        ts = try Self.decodeTime(from: container)
        sender = try container.decode(EventSender.self, forKey: .sender)
        kind = try container.decode(EventKind.self, forKey: .kind)
        topic = try container.decode(EventTopic.self, forKey: .topic)
        summary = try container.decode(String.self, forKey: .summary)
        data = try container.decode([String: JSONValue].self, forKey: .data)
        undo = try container.decodeIfPresent(EventUndo.self, forKey: .undo)
        causedBy = try container.decodeIfPresent(String.self, forKey: .causedBy)
        attention = try container.decode(EventAttention.self, forKey: .attention)
    }

    private static func decodeTime(from container: KeyedDecodingContainer<CodingKeys>) throws -> Date {
        let text = try container.decode(String.self, forKey: .ts)
        let styles = [Date.ISO8601FormatStyle(), Date.ISO8601FormatStyle(includingFractionalSeconds: true)]
        for style in styles {
            if let date = try? style.parse(text) {
                return date
            }
        }
        throw DecodingError.dataCorruptedError(forKey: .ts, in: container, debugDescription: "Not ISO 8601 with an offset: \(text)")
    }
}
