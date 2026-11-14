/// Your answer to a permission request, as in Claude Code's own prompt.
public enum PermissionAnswer: String, Sendable, Equatable, Hashable {
    /// Yes, this once.
    case allow
    /// Yes, and don't ask again for this, by Claude Code's suggestion.
    case allowAlways
    /// No.
    case deny

    /// The answer as Claude Code reads it, for `request`.
    public func response(to request: PermissionRequest) -> JSONValue {
        switch self {
        case .allow:
            .object(["behavior": .string("allow"), "updatedInput": request.input])
        case .allowAlways:
            .object(["behavior": .string("allow"), "updatedInput": request.input, "updatedPermissions": .array(request.suggestions)])
        case .deny:
            .object(["behavior": .string("deny"), "message": .string("The user denied this.")])
        }
    }
}
