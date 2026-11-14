import Foundation

/// Where your scheduled jobs are kept: one JSON file in Swift's folder.
public struct JobStore: Sendable {
    /// The file.
    public let file: URL

    /// A store for the file at `file`.
    public init(at file: URL) {
        self.file = file
    }

    /// The saved jobs, or none if nothing is saved yet.
    public func load() throws -> [SwiftJob] {
        guard FileManager.default.fileExists(atPath: file.path) else { return [] }
        return try JSONDecoder().decode([SwiftJob].self, from: Data(contentsOf: file))
    }

    /// Saves `jobs`, replacing what was there.
    public func save(_ jobs: [SwiftJob]) throws {
        try FileManager.default.createDirectory(at: file.deletingLastPathComponent(), withIntermediateDirectories: true)
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        try encoder.encode(jobs).write(to: file, options: .atomic)
    }
}
