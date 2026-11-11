import Foundation

/// One invented day of events from the whole flock, for building the app before the birds exist.
public enum DemoDay {
    /// The bundled `demo-day.jsonl`.
    public static var url: URL {
        get throws {
            guard let url = Bundle.module.url(forResource: "demo-day", withExtension: "jsonl") else {
                throw CocoaError(.fileNoSuchFile)
            }
            return url
        }
    }

    /// Every event in the demo day, in the order written.
    public static func events() throws -> [NestEvent] {
        try NestEvent.lines(Data(contentsOf: url))
    }
}
