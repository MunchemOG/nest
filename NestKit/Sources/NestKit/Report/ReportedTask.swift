/// One task as Swift reports it: how it ended, the tests it added, and, if it did not merge, why and Swift's best guess.
public struct ReportedTask: Sendable, Equatable {
    /// The task's id.
    public let id: String
    /// How it ended.
    public let ending: TaskEnding
    /// New tests it added.
    public let testsAdded: Int
    /// What went wrong, if it did not merge.
    public let why: String?
    /// Swift's best guess at the cause.
    public let guess: String?
    /// How sure Swift is of its guess (0 to 1).
    public let confidence: Double?

    /// A task with the given ending, tests and, if it did not merge, the reason and guess.
    public init(id: String, ending: TaskEnding, testsAdded: Int, why: String? = nil, guess: String? = nil, confidence: Double? = nil) {
        self.id = id
        self.ending = ending
        self.testsAdded = testsAdded
        self.why = why
        self.guess = guess
        self.confidence = confidence
    }
}
