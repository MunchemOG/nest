import Foundation

extension JSONValue: Encodable {
    /// Encodes the value as the JSON it came from.
    public func encode(to encoder: any Encoder) throws {
        var container = encoder.singleValueContainer()
        switch self {
        case .string(let value): try container.encode(value)
        case .number(let value): try container.encode(value)
        case .bool(let value): try container.encode(value)
        case .object(let value): try container.encode(value)
        case .array(let value): try container.encode(value)
        case .null: try container.encodeNil()
        }
    }
}

extension JSONValue {
    /// The value under `key`, if this is an object that has one.
    public subscript(key: String) -> JSONValue? {
        if case .object(let object) = self { object[key] } else { nil }
    }

    /// The string, if this is one.
    public var string: String? {
        if case .string(let value) = self { value } else { nil }
    }

    /// The number, if this is one.
    public var number: Double? {
        if case .number(let value) = self { value } else { nil }
    }

    /// The array, if this is one.
    public var array: [JSONValue]? {
        if case .array(let value) = self { value } else { nil }
    }

    /// The JSON in `line`, or nil if it isn't JSON.
    public init?(line: String) {
        guard let value = try? JSONDecoder().decode(JSONValue.self, from: Data(line.utf8)) else { return nil }
        self = value
    }
}
