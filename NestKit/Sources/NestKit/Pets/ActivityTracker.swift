import Foundation

/// Tracks how long Mithun has been working without a real pause.
public struct ActivityTracker: Sendable {
    private let breakPause: TimeInterval
    private var start: Date?
    private var lastSample: Date?

    /// A tracker where a pause of `breakPause` seconds or more ends the streak.
    public init(breakPause: TimeInterval) {
        self.breakPause = breakPause
    }

    /// The current streak in seconds, after taking one sample.
    public mutating func streak(now: Date, secondsSinceInput: TimeInterval) -> TimeInterval {
        defer { lastSample = now }
        if secondsSinceInput >= breakPause {
            start = nil
            return 0
        }
        if let lastSample, now.timeIntervalSince(lastSample) >= breakPause {
            start = now
            return 0
        }
        let begun = start ?? now
        start = begun
        return now.timeIntervalSince(begun)
    }
}
