/// How a session says its task ended.
public enum SummaryResult: String, Sendable, Equatable {
    case done
    case held
    case unclear
}
