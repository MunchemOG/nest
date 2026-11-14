import Foundation

/// Where a project's repository stands: the branch it's on and how many files have changed.
public struct ProjectStatus: Sendable, Equatable {
    /// The branch checked out, or nil if the folder isn't a git repository.
    public let branch: String?
    /// How many files are changed or new.
    public let changed: Int

    /// A status with these fields.
    public init(branch: String?, changed: Int) {
        self.branch = branch
        self.changed = changed
    }

    /// The status of the repository at `folder`.
    public static func read(_ folder: URL) async -> ProjectStatus {
        let shell = Shell()
        guard let branch = try? await shell.run(["git", "branch", "--show-current"], in: folder), branch.succeeded else {
            return ProjectStatus(branch: nil, changed: 0)
        }
        let status = try? await shell.run(["git", "status", "--porcelain"], in: folder)
        let changed = status?.text.split(separator: "\n").count ?? 0
        return ProjectStatus(branch: branch.text.trimmingCharacters(in: .whitespacesAndNewlines), changed: changed)
    }
}
