import Foundation

/// Makes event ids: `evt_` and a ULID, so ids sort by time.
public enum EventID {
    static let alphabet = Array("0123456789ABCDEFGHJKMNPQRSTVWXYZ")

    /// A new id for an event at `time`.
    public static func make(at time: Date = .now) -> String {
        var random = SystemRandomNumberGenerator()
        return make(at: time, using: &random)
    }

    /// A new id for an event at `time`, drawing its random part from `random`.
    public static func make(at time: Date, using random: inout some RandomNumberGenerator) -> String {
        var randomPart = ""
        for _ in 0..<16 {
            randomPart.append(alphabet[Int(random.next() % 32)])
        }
        return "evt_" + timePart(at: time) + randomPart
    }

    /// The ULID's first ten characters: milliseconds since 1970 in Crockford base 32.
    static func timePart(at time: Date) -> String {
        var millis = UInt64(max(0, time.timeIntervalSince1970 * 1000).rounded(.down))
        var characters = [Character](repeating: "0", count: 10)
        for index in stride(from: 9, through: 0, by: -1) {
            characters[index] = alphabet[Int(millis % 32)]
            millis /= 32
        }
        return String(characters)
    }
}
