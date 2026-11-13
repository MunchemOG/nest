import Foundation

/// What a task branch changed compared with where it started, file by file.
public struct BranchDiff: Sendable, Equatable {
    /// Every file the branch changed, in the order git lists them.
    public let files: [ChangedFile]

    /// A diff of the given files.
    public init(files: [ChangedFile]) {
        self.files = files
    }

    /// The diff in `text`, the output of `git diff --unified=0 --no-renames`.
    public init(text: String) {
        var files: [ChangedFile] = []
        var path: String?
        var added: [String] = []
        var removed: [String] = []
        var isDeleted = false
        var isSymlink = false
        func close() {
            if let path { files.append(ChangedFile(path: path, added: added, removed: removed, isDeleted: isDeleted, isSymlink: isSymlink)) }
            path = nil; added = []; removed = []; isDeleted = false; isSymlink = false
        }
        var inHunk = false
        for line in text.split(separator: "\n", omittingEmptySubsequences: false).map(String.init) {
            if line.hasPrefix("diff --git ") {
                close()
                inHunk = false
                path = line.split(separator: " b/", maxSplits: 1).last.map(String.init)
            } else if !inHunk {
                if line.hasPrefix("deleted file mode") { isDeleted = true }
                if line.hasSuffix("mode 120000") { isSymlink = true }
                if line.hasPrefix("@@") { inHunk = true }
            } else if line.hasPrefix("+") {
                added.append(String(line.dropFirst()))
            } else if line.hasPrefix("-") {
                removed.append(String(line.dropFirst()))
            }
        }
        close()
        self.files = files
    }

    /// What `branch` changed since it left `base`, read with git in `repository`.
    public init(base: String, branch: String, in repository: URL) async throws {
        let output = try await Shell().run(
            ["git", "diff", "--unified=0", "--no-renames", "--no-color", "--no-ext-diff", "\(base)...\(branch)"],
            in: repository
        )
        guard output.succeeded else { throw ManualRunnerError.git(output.text) }
        self.init(text: output.text)
    }
}
