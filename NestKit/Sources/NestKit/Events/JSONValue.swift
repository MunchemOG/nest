/// Any JSON value, kept as it was written: the shape of an event's `data` and undo `args`.
public enum JSONValue: Hashable, Sendable, Decodable {
    /// A string.
    case string(String)
    /// A number.
    case number(Double)
    /// true or false.
    case bool(Bool)
    /// An object, by key.
    case object([String: JSONValue])
    /// An array.
    case array([JSONValue])
    /// null.
    case null

    /// Decodes whichever JSON value comes next.
    public init(from decoder: any Decoder) throws {
        let container = try decoder.singleValueContainer()
        if container.decodeNil() {
            self = .null
        } else if let value = try? container.decode(Bool.self) {
            self = .bool(value)
        } else if let value = try? container.decode(Double.self) {
            self = .number(value)
        } else if let value = try? container.decode(String.self) {
            self = .string(value)
        } else if let value = try? container.decode([JSONValue].self) {
            self = .array(value)
        } else {
            self = .object(try container.decode([String: JSONValue].self))
        }
    }
}
