/// Where a task is in Swift's queue.
public enum QueueState: String, Sendable, Equatable, CaseIterable {
    /// Waiting to be built.
    case queued
    /// Taken by a run that is building it now.
    case claimed
    /// Built, with its tests passing.
    case done
    /// Stopped short; it waits for you.
    case held
}
