import Foundation

/// Claude Code's own record of your sessions, kept per folder in `~/.claude/projects/`. Swift only reads it.
public struct ClaudeHistory: Sendable {
    /// Claude Code's home folder.
    public let home: URL

    /// The history kept under `home`.
    public init(home: URL = FileManager.default.homeDirectoryForCurrentUser.appending(path: ".claude")) {
        self.home = home
    }

    /// The name Claude Code gives a folder's history: its real path (links followed, so `/tmp` is `/private/tmp`)
    /// with everything but letters and digits made a dash.
    public static func folderName(for folder: URL) -> String {
        String(realPath(folder).map { $0.isLetter || $0.isNumber ? $0 : "-" })
    }

    /// The folder's path with every link followed, as the system resolves it; the path as given if it doesn't exist.
    static func realPath(_ folder: URL) -> String {
        let path = folder.standardizedFileURL.path
        guard let resolved = realpath(path, nil) else { return path }
        defer { free(resolved) }
        return String(cString: resolved)
    }

    /// The sessions run in `folder`, the most recent first.
    public func sessions(in folder: URL) -> [PastSession] {
        files(in: historyFolder(for: folder)).compactMap { file in
            let lines = Self.lines(of: file)
            let yours = lines.compactMap(Self.yours)
            guard let last = yours.map(\.time).max() else { return nil }
            let summary = lines.lazy.compactMap { line -> String? in
                guard line["type"]?.string == "summary" || line["type"]?.string == "custom-title" else { return nil }
                return line["summary"]?.string ?? line["customTitle"]?.string
            }.first
            let first = yours.first?.text.split(separator: "\n").first.map(String.init) ?? ""
            return PastSession(id: file.deletingPathExtension().lastPathComponent, title: summary ?? Self.short(first),
                               lastActive: last, messages: yours.count)
        }
        .sorted { $0.lastActive > $1.lastActive }
    }

    /// How many messages you sent in `folder` on each of the `days` days ending with `until`'s day, oldest first.
    public func activity(in folder: URL, days: Int, until: Date, calendar: Calendar = .current) -> [Int] {
        let end = calendar.startOfDay(for: until)
        var counts = Array(repeating: 0, count: days)
        for file in files(in: historyFolder(for: folder)) {
            for message in Self.lines(of: file).compactMap(Self.yours) {
                let day = calendar.dateComponents([.day], from: calendar.startOfDay(for: message.time), to: end).day ?? days
                if day >= 0, day < days { counts[days - 1 - day] += 1 }
            }
        }
        return counts
    }

    /// When you sent each message to Claude Code, in every project.
    public func yourMessages() -> [Date] {
        let projects = home.appending(path: "projects")
        let folders = (try? FileManager.default.contentsOfDirectory(at: projects, includingPropertiesForKeys: nil)) ?? []
        return folders.flatMap { files(in: $0) }.flatMap { Self.lines(of: $0).compactMap(Self.yours).map(\.time) }
    }

    /// A past session in `folder` as a transcript: what you said, Claude's replies, and the tools it used.
    public func transcript(of session: String, in folder: URL) -> SessionTranscript {
        var transcript = SessionTranscript(folder: folder.path)
        for line in Self.lines(of: historyFolder(for: folder).appending(path: "\(session).jsonl")) {
            if let yours = Self.yours(line) {
                transcript.add(you: yours.text)
            } else if let data = try? JSONEncoder().encode(line), let event = ClaudeEvent(line: String(decoding: data, as: UTF8.self)) {
                if case .finished = event { continue }
                transcript.apply(event)
            }
        }
        transcript.settle()
        return transcript
    }

    private func historyFolder(for folder: URL) -> URL {
        home.appending(path: "projects").appending(path: Self.folderName(for: folder))
    }

    private func files(in folder: URL) -> [URL] {
        ((try? FileManager.default.contentsOfDirectory(at: folder, includingPropertiesForKeys: nil)) ?? [])
            .filter { $0.pathExtension == "jsonl" }
    }

    private static func lines(of file: URL) -> [JSONValue] {
        guard let text = try? String(contentsOf: file, encoding: .utf8) else { return [] }
        return text.split(separator: "\n").compactMap { JSONValue(line: String($0)) }
    }

    /// A message you typed: a user line whose content is text, not a tool's result or a command's echo.
    private static func yours(_ line: JSONValue) -> (text: String, time: Date)? {
        guard line["type"]?.string == "user", let text = line["message"]?["content"]?.string, !text.hasPrefix("<"),
              let stamp = line["timestamp"]?.string, let time = stampFormat.date(from: stamp) ?? plainFormat.date(from: stamp)
        else { return nil }
        return (text, time)
    }

    private static func short(_ text: String) -> String {
        text.count > 60 ? String(text.prefix(59)) + "…" : text
    }

    nonisolated(unsafe) private static let stampFormat: ISO8601DateFormatter = {
        let format = ISO8601DateFormatter()
        format.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return format
    }()

    nonisolated(unsafe) private static let plainFormat = ISO8601DateFormatter()
}
