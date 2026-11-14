/// How hard a session thinks, as Claude Code's `--effort` takes it.
public enum Effort: String, Sendable, Equatable, CaseIterable, Codable {
    /// Quick answers.
    case low
    /// Some thought.
    case medium
    /// Careful work.
    case high
    /// More careful still.
    case xhigh
    /// As hard as it can.
    case max

    /// The effort's name as you see it.
    public var name: String {
        switch self {
        case .low: "Low"
        case .medium: "Med"
        case .high: "High"
        case .xhigh: "X-High"
        case .max: "Max"
        }
    }
}
