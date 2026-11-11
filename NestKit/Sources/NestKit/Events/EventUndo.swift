/// Everything needed to reverse an event: an undo op and its arguments.
public struct EventUndo: Hashable, Sendable, Decodable {
    /// The undo op, such as `file.move`.
    public let op: String
    /// The op's arguments.
    public let args: [String: JSONValue]

    /// An undo from its op and arguments.
    public init(op: String, args: [String: JSONValue]) {
        self.op = op
        self.args = args
    }
}
