/// What Swift knows of whether you are at the Mac, from the `owl.presence.changed` events it hears.
public actor PresenceWatch {
    /// The latest presence (`here`, `away`, `stranger` or `guest`), or nil before any was heard.
    public private(set) var current: String?

    /// A watch that has heard nothing yet.
    public init() {}

    /// Hears one event; only presence changes matter.
    public func receive(_ event: NestEvent) {
        guard event.topic == .owlPresenceChanged, case .string(let to)? = event.data["to"] else { return }
        current = to
    }

    /// Whether Swift must stand down: you are here, or someone Owl does not know is.
    public var standsSwiftDown: Bool { current == "here" || current == "stranger" }

    /// Why Swift stood down, in a sentence you can read.
    public var reason: String {
        current == "stranger" ? "Someone Owl does not know is here, so Swift stood down." : "You're here, so Swift stood down."
    }
}
