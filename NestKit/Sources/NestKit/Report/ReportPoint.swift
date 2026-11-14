/// One of a report's three points: a figure and the words after it.
public struct ReportPoint: Sendable, Equatable {
    /// The figure, such as "+14" or "38%".
    public let figure: String
    /// What it means, such as "new tests; the safety net is now 212."
    public let text: String

    /// A point with the given figure and text.
    public init(figure: String, text: String) {
        self.figure = figure
        self.text = text
    }
}
