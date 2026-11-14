import Foundation
import Testing
@testable import NestKit

struct ClaudeHistoryTests {
    static let utc = TimeZone(identifier: "UTC")!
    static var calendar: Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = utc
        return calendar
    }

    static func line(_ type: String, _ content: String, at time: String) -> String {
        let text = try! JSONEncoder().encode(content)
        return #"{"type":"\#(type)","message":{"role":"\#(type)","content":\#(String(decoding: text, as: UTF8.self))},"timestamp":"\#(time)"}"#
    }

    /// A Claude Code home with two sessions in `/Users/someone/Robotics/swerve_drive` and one in another project.
    func home() throws -> URL {
        let home = FileManager.default.temporaryDirectory.appending(path: "ClaudeHistoryTests-\(UUID().uuidString)")
        let swerve = home.appending(path: "projects/-Users-someone-Robotics-swerve-drive")
        let other = home.appending(path: "projects/-Users-someone-School")
        for folder in [swerve, other] { try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true) }
        try [
            Self.line("user", "<command-name>/clear</command-name>", at: "2026-11-10T09:00:00.000Z"),
            Self.line("user", "Log the auton path\nso we can replay it", at: "2026-11-10T09:00:05.000Z"),
            #"{"type":"assistant","message":{"id":"m1","role":"assistant","content":[{"type":"text","text":"Sure."}]},"timestamp":"2026-11-10T09:00:09.000Z"}"#,
            Self.line("user", "now add a test", at: "2026-11-12T20:15:00.000Z"),
        ].joined(separator: "\n").write(to: swerve.appending(path: "aaa.jsonl"), atomically: true, encoding: .utf8)
        try [
            #"{"type":"summary","summary":"Tune the swerve PID"}"#,
            Self.line("user", "the wheels oscillate", at: "2026-11-13T22:00:00.000Z"),
            #"{"type":"user","message":{"role":"user","content":[{"type":"tool_result","tool_use_id":"t","content":"ok"}]},"timestamp":"2026-11-13T22:01:00.000Z"}"#,
        ].joined(separator: "\n").write(to: swerve.appending(path: "bbb.jsonl"), atomically: true, encoding: .utf8)
        try Self.line("user", "physics", at: "2026-11-11T10:00:00.000Z")
            .write(to: other.appending(path: "ccc.jsonl"), atomically: true, encoding: .utf8)
        return home
    }

    @Test func claudeCodeNamesAFoldersHistoryByItsPath() {
        #expect(ClaudeHistory.folderName(for: URL(fileURLWithPath: "/Users/someone/Robotics/swerve_drive"))
                == "-Users-someone-Robotics-swerve-drive")
        #expect(ClaudeHistory.folderName(for: URL(fileURLWithPath: "/Users/someone/Developer/nest")) == "-Users-someone-Developer-nest")
    }

    @Test func aProjectListsItsSessionsNewestFirstWithTitles() throws {
        let home = try home()
        defer { try? FileManager.default.removeItem(at: home) }
        let history = ClaudeHistory(home: home)

        let sessions = history.sessions(in: URL(fileURLWithPath: "/Users/someone/Robotics/swerve_drive"))

        #expect(sessions.map(\.id) == ["bbb", "aaa"])
        #expect(sessions.map(\.title) == ["Tune the swerve PID", "Log the auton path"])
        #expect(sessions.map(\.messages) == [1, 2])
        #expect(sessions.last?.lastActive == ISO8601DateFormatter().date(from: "2026-11-12T20:15:00Z"))
        #expect(history.sessions(in: URL(fileURLWithPath: "/nowhere")).isEmpty)
    }

    @Test func theStripCountsYourMessagesPerDay() throws {
        let home = try home()
        defer { try? FileManager.default.removeItem(at: home) }
        let history = ClaudeHistory(home: home)
        let today = ISO8601DateFormatter().date(from: "2026-11-14T12:00:00Z")!

        let strip = history.activity(in: URL(fileURLWithPath: "/Users/someone/Robotics/swerve_drive"), days: 5, until: today,
                                     calendar: Self.calendar)

        #expect(strip == [1, 0, 1, 1, 0])
    }

    @Test func everyMessageYouSentIsKnownForLearningYourWeek() throws {
        let home = try home()
        defer { try? FileManager.default.removeItem(at: home) }
        let times = ClaudeHistory(home: home).yourMessages()
        #expect(times.count == 4)
        #expect(times.sorted().first == ISO8601DateFormatter().date(from: "2026-11-10T09:00:05Z"))
    }

    @Test func aProjectShowsItsBranchAndChangedFiles() async throws {
        let repo = try await TempRepo()
        defer { repo.remove() }
        try "changed\n".write(to: repo.url.appending(path: "README.md"), atomically: true, encoding: .utf8)
        try "new\n".write(to: repo.url.appending(path: "new.txt"), atomically: true, encoding: .utf8)

        let status = await ProjectStatus.read(repo.url)

        #expect(status == ProjectStatus(branch: "main", changed: 2))
        let plain = FileManager.default.temporaryDirectory.appending(path: "plain-\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: plain, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: plain) }
        #expect(await ProjectStatus.read(plain) == ProjectStatus(branch: nil, changed: 0))
    }

    @Test func eachProjectHasATileColourYouCanChange() {
        var project = SwiftProject(id: "swerve-drive", name: "swerve_drive", folder: "/x")
        let first = project.tile
        #expect(ProjectTile.allCases.contains(first))
        #expect(SwiftProject(id: "swerve-drive", name: "other", folder: "/y").tile == first)
        project.tint = .lagoon
        #expect(project.tile == .lagoon)
        #expect(project.initial == "S")
        #expect(SwiftProject.nest(at: URL(fileURLWithPath: "/n")).initial == "N")
    }

    @Test func aPastSessionReadsBackAsATranscript() throws {
        let home = try home()
        defer { try? FileManager.default.removeItem(at: home) }
        let transcript = ClaudeHistory(home: home).transcript(of: "aaa", in: URL(fileURLWithPath: "/Users/someone/Robotics/swerve_drive"))
        #expect(transcript.items.map(\.kind) == [.you, .claude, .you])
        #expect(transcript.items.map(\.text) == ["Log the auton path\nso we can replay it", "Sure.", "now add a test"])
        #expect(!transcript.isWorking)
    }
}
