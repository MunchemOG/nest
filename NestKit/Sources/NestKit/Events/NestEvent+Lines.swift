import Foundation

extension NestEvent {
    /// Decodes JSONL: one event per line, skipping blank lines.
    public static func lines(_ data: Data) throws -> [NestEvent] {
        let decoder = JSONDecoder()
        let text = String(decoding: data, as: UTF8.self)
        var events: [NestEvent] = []
        for (index, line) in text.split(separator: "\n", omittingEmptySubsequences: false).enumerated() {
            guard !line.allSatisfy(\.isWhitespace) else { continue }
            do {
                events.append(try decoder.decode(NestEvent.self, from: Data(line.utf8)))
            } catch {
                throw LineError(line: index + 1, underlying: error)
            }
        }
        return events
    }
}
