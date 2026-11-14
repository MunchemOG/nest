/// Why a folder could not become a project.
public enum SwiftProjectError: Error, Equatable {
    /// The folder is not a git repository with a branch checked out.
    case notARepository(String)
}
