import Foundation

/// The Mac's active minutes, counted per hour and kept only on this Mac: no apps, no keys, just whether you were there.
public struct ActivityLog: Sendable {
    /// The file.
    public let file: URL

    /// How long activity is kept.
    public static let keep: TimeInterval = 5 * 7 * 86_400

    /// A log kept in the file at `file`.
    public init(at file: URL) {
        self.file = file
    }

    /// Records that you were active in the minute `time` falls in; the same minute counts once.
    public func record(activeAt time: Date) throws {
        var minutes = try load()
        minutes.insert(Int(time.timeIntervalSince1970 / 60))
        let oldest = Int((time.timeIntervalSince1970 - Self.keep) / 60)
        minutes = minutes.filter { $0 >= oldest }
        try FileManager.default.createDirectory(at: file.deletingLastPathComponent(), withIntermediateDirectories: true)
        try JSONEncoder().encode(minutes.sorted()).write(to: file, options: .atomic)
    }

    /// Active minutes per hour, keyed by the hour's start, for the weeks kept before `now`.
    public func hours(now: Date = .now) throws -> [Date: Int] {
        let oldest = Int((now.timeIntervalSince1970 - Self.keep) / 60)
        var hours: [Date: Int] = [:]
        for minute in try load() where minute >= oldest {
            hours[Date(timeIntervalSince1970: Double(minute / 60 * 3600)), default: 0] += 1
        }
        return hours
    }

    private func load() throws -> Set<Int> {
        guard FileManager.default.fileExists(atPath: file.path) else { return [] }
        return Set(try JSONDecoder().decode([Int].self, from: Data(contentsOf: file)))
    }
}
