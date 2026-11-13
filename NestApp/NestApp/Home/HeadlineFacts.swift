import Foundation
import NestKit

/// The few facts the Home headline is made from, kept up to date event by event.
struct HeadlineFacts: Hashable, Sendable {
    /// The task Swift is building in its current run, if a run is going.
    private(set) var building: String?
    /// When Focus mode ends, while it is on.
    private(set) var focusUntil: String?
    /// Whether you are in flow.
    private(set) var inFlow = false
    /// When the current flow began.
    private(set) var flowSince: Date?
    /// Where you are: `here`, `away`, `stranger` or `guest`.
    private(set) var presence: String?
    /// The Mac's mode, such as `Morning`, `Focus` or `Night`.
    private(set) var mode: String?
    /// When the current mode began.
    private(set) var modeSince: Date?
    /// The accent Wren's look chose, such as `clay` or `lagoon`.
    private(set) var accent: String?
    /// Whether the current mode turned notifications off.
    private(set) var notificationsOff = false

    private var runTasks: [String] = []

    mutating func apply(_ event: NestEvent) {
        switch event.topic {
        case .swiftRunStarted:
            runTasks = event.data["tasks"]?.strings ?? []
            building = runTasks.first
        case .swiftRunFinished:
            runTasks = []
            building = nil
        case .swiftTaskMerged, .swiftTaskHeld, .swiftTaskFailed:
            guard let task = event.data["task"]?.string, let index = runTasks.firstIndex(of: task) else { return }
            building = runTasks.indices.contains(index + 1) ? runTasks[index + 1] : nil
        case .wrenModeChanged:
            mode = event.data["to"]?.string
            modeSince = event.ts
            let settings = event.data["settings"]?.object
            notificationsOff = settings?["notifications"]?.string == "off"
            focusUntil = mode == "Focus" ? settings?["until"]?.string : nil
        case .wrenLookChanged:
            accent = event.data["accent"]?.string
        case .owlFlowChanged:
            inFlow = event.data["to"]?.bool ?? false
            flowSince = inFlow ? event.ts : nil
        case .owlPresenceChanged:
            presence = event.data["to"]?.string
        default:
            break
        }
    }
}

extension JSONValue {
    var string: String? { if case .string(let value) = self { value } else { nil } }
    var bool: Bool? { if case .bool(let value) = self { value } else { nil } }
    var object: [String: JSONValue]? { if case .object(let value) = self { value } else { nil } }
    var strings: [String]? { if case .array(let values) = self { values.compactMap(\.string) } else { nil } }
}
