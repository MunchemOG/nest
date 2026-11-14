import Foundation

/// Where Swift's settings are kept on this Mac: one JSON file in Swift's folder.
public struct SwiftSettingsStore: Sendable {
    /// The settings file.
    public let file: URL
    /// The Nest's repository, used the first time, before you have saved anything.
    public let nest: URL

    /// A store for the file at `file`; until it exists, the settings hold the Nest at `nest`.
    public init(at file: URL, nest: URL) {
        self.file = file
        self.nest = nest
    }

    /// The saved settings, or the first-time settings if none are saved.
    public func load() throws -> SwiftSettings {
        guard FileManager.default.fileExists(atPath: file.path) else {
            return SwiftSettings(limits: .standard, projects: [.nest(at: nest)])
        }
        return try JSONDecoder().decode(SwiftSettings.self, from: Data(contentsOf: file))
    }

    /// Saves `settings`, replacing what was there.
    public func save(_ settings: SwiftSettings) throws {
        try FileManager.default.createDirectory(at: file.deletingLastPathComponent(), withIntermediateDirectories: true)
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        try encoder.encode(settings).write(to: file, options: .atomic)
    }
}
