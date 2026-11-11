import Foundation

/// What the app knows about one bird, built from its events.
public struct BirdState: Hashable, Sendable {
    /// How long after its latest event a bird still counts as active: ten minutes.
    public static let activeWindow: TimeInterval = 10 * 60

    /// When the bird last published anything, or nil if never.
    public var lastHeard: Date?
    /// The bird's newest event that changed something: an action, undo or note.
    public var latestAction: NestEvent?
    /// The summary of the bird's newest event: the "doing" line.
    public var doing: String?
    /// Whether the app has paused the bird.
    public var isPaused = false

    /// A bird nothing has been heard about.
    public init() {}

    /// The bird's status at `now`.
    public func status(at now: Date) -> BirdStatus {
        if isPaused {
            return .paused
        }
        guard let lastHeard else {
            return .asleep
        }
        return now.timeIntervalSince(lastHeard) <= Self.activeWindow ? .active : .resting
    }
}
