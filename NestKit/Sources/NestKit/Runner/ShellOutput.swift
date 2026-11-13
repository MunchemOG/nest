/// What a command printed and how it ended.
public struct ShellOutput: Sendable, Equatable {
    /// The command's exit status; zero means it succeeded.
    public let status: Int32
    /// Everything the command printed, errors included.
    public let text: String

    /// Whether the command exited with status zero.
    public var succeeded: Bool { status == 0 }
}
