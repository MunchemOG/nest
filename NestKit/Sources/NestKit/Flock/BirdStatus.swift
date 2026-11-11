/// How a bird is doing right now.
public enum BirdStatus: String, CaseIterable, Hashable, Sendable {
    /// Not heard from yet: not built, or not running.
    case asleep
    /// Heard from, but quiet lately.
    case resting
    /// Did something in the last `BirdState.activeWindow` seconds.
    case active
    /// Paused from the app; publishes only signals about itself.
    case paused
}
