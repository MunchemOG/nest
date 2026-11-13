import Foundation

/// Finds changes that reach outside the repository: paths that climb out of it, and links that point out of it.
public enum RepositoryBoundsCheck {
    /// One line per change that leaves the repository.
    public static func problems(in diff: BranchDiff) -> [String] {
        diff.files.compactMap { file in
            if escapes(file.path, from: "") { return "\(file.path) is outside the repository" }
            guard file.isSymlink, let target = file.added.first else { return nil }
            let folder = (file.path as NSString).deletingLastPathComponent
            return target.hasPrefix("/") || target.hasPrefix("~") || escapes(target, from: folder)
                ? "\(file.path) points outside the repository (\(target))" : nil
        }
    }

    /// Whether `path`, read from `folder` inside the repository, climbs above the repository's root.
    private static func escapes(_ path: String, from folder: String) -> Bool {
        var depth = folder.split(separator: "/").count
        for part in path.split(separator: "/") {
            if part == ".." { depth -= 1 } else if part != "." { depth += 1 }
            if depth < 0 { return true }
        }
        return false
    }
}
