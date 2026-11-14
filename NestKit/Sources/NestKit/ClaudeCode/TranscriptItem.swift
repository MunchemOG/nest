/// One thing in a session's transcript.
public struct TranscriptItem: Sendable, Equatable, Identifiable {
    /// What kind of thing it is.
    public enum Kind: Sendable, Equatable {
        /// What you said.
        case you
        /// What Claude said.
        case claude
        /// A tool Claude used.
        case tool
        /// Claude asking to use one.
        case permission
        /// The end of a turn.
        case finished
    }

    /// A permission request and your answer, once given.
    public struct Permission: Sendable, Equatable {
        /// The request.
        public let request: PermissionRequest
        /// Your answer, or nil while it waits.
        public var answer: PermissionAnswer?
    }

    /// A stable id for the view.
    public let id: String
    /// What kind of thing it is.
    public let kind: Kind
    /// Its text: yours, Claude's, or how the turn ended.
    public var text: String
    /// The tool call, for a tool item.
    public var tool: ToolCard?
    /// The request, for a permission item.
    public var permission: Permission?
    /// Whether Claude is still writing it.
    public var isStreaming: Bool
}
