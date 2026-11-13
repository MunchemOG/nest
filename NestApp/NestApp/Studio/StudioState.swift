import Foundation
import NestKit

/// What the 3D studio needs to know, in the shape `window.nest.set` takes.
struct StudioState: Hashable, Sendable {
    /// `asleep`, `working`, `idle` or `paused`, by bird id.
    var statuses: [String: String] = [:]
    /// The line under each bird's tile, by bird id.
    var tagLines: [String: String] = [:]
    /// How far through its job each bird is, from 0 to 1, by bird id.
    var progress: [String: Double] = [:]
    /// The Mac's mode and, in Focus, when it ends.
    var mode = "Night"
    var until: String?

    /// The state as JavaScript object literal text.
    var script: String {
        let object: [String: Any] = [
            "statuses": statuses,
            "tagLines": tagLines,
            "progress": progress,
            "mode": ["label": mode, "until": until.map { $0 as Any } ?? NSNull()],
        ]
        let data = (try? JSONSerialization.data(withJSONObject: object, options: [.sortedKeys])) ?? Data("{}".utf8)
        return String(decoding: data, as: UTF8.self)
    }
}
