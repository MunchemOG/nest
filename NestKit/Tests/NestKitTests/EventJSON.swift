import Foundation
@testable import NestKit

/// Builds one event as JSON text, with every field the contract requires.
enum EventJSON {
    static func make(
        bird: String = "wren",
        kind: String = "signal",
        topic: String = "wren.file.skipped",
        ts: String = "2026-11-10T08:14:07-06:00",
        attention: String = "none",
        data: String = "{}",
        undo: String = "null",
        causedBy: String = "null"
    ) -> String {
        """
        {"id": "evt_01JCF8Q2X9M4", "ts": "\(ts)", "bird": "\(bird)", "kind": "\(kind)", "topic": "\(topic)", \
        "summary": "Something happened", "data": \(data), "undo": \(undo), "caused_by": \(causedBy), "attention": "\(attention)"}
        """
    }

    static func decode(_ json: String) throws -> NestEvent {
        try JSONDecoder().decode(NestEvent.self, from: Data(json.utf8))
    }
}
