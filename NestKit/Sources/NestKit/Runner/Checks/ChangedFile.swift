/// One file a branch changed: its path and the lines it added and removed.
public struct ChangedFile: Sendable, Equatable {
    /// The file's path from the repository's root.
    public let path: String
    /// Lines the branch added, without the leading `+`.
    public let added: [String]
    /// Lines the branch removed, without the leading `-`.
    public let removed: [String]
    /// Whether the branch deleted the file.
    public let isDeleted: Bool
    /// Whether the file is a symbolic link; its one added line is where it points.
    public let isSymlink: Bool

    /// A changed file with the given lines.
    public init(path: String, added: [String], removed: [String], isDeleted: Bool = false, isSymlink: Bool = false) {
        self.path = path
        self.added = added
        self.removed = removed
        self.isDeleted = isDeleted
        self.isSymlink = isSymlink
    }

    /// Whether the file holds tests: in a folder named `…Tests`, or named `…Tests.swift`.
    public var isTest: Bool {
        let parts = path.split(separator: "/")
        return parts.dropLast().contains { $0.hasSuffix("Tests") } || parts.last?.hasSuffix("Tests.swift") == true
    }

    /// Whether the file is Swift code that ships, not a test.
    public var isSource: Bool { path.hasSuffix(".swift") && !isTest }
}
