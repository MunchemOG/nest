import Foundation
import NestKit
import Testing
@testable import NestApp

@MainActor
struct SwiftOnThisMacTests {
    static let repository = URL(fileURLWithPath: "/tmp/nest-repo")

    func folder() throws -> URL {
        let url = FileManager.default.temporaryDirectory.appending(path: "SwiftOnThisMacTests-\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
        return url
    }

    @Test func theNightRunnerDrivesClaudeCodeInTheRepositoryAndRunsTheWholeSuite() async throws {
        let folder = try folder()
        defer { try? FileManager.default.removeItem(at: folder) }
        let presence = PresenceWatch()

        let runner = try await SwiftOnThisMac.runner(repository: Self.repository, folder: folder, presence: presence) { _ in }

        #expect(runner.runner.repository == Self.repository)
        #expect(runner.runner.session.prefix(2) == ["/bin/sh", "-c"])
        #expect(runner.runner.session[2].contains("exec claude -p --output-format stream-json"))
        #expect(runner.runner.tests == ["scripts/test.sh", "all"])
        #expect(runner.mainTests == ["scripts/test.sh", "all"])
        #expect(runner.merger?.repository == Self.repository)
        #expect(runner.budget?.rules == SwiftOnThisMac.rules)
        #expect(runner.usageLog != nil)
        #expect(runner.presence === presence)
    }

    @Test func swiftHearsTheSwitchInTheOrderYouFlippedIt() async throws {
        let swift = SwiftOnThisMac()

        swift.hear("away")
        swift.hear("here")
        swift.hear("away")

        for _ in 0..<200 where await swift.presence.current != "away" {
            try await Task.sleep(for: .milliseconds(5))
        }
        #expect(await swift.presence.current == "away")
        swift.hear("here")
        for _ in 0..<200 where await swift.presence.current != "here" {
            try await Task.sleep(for: .milliseconds(5))
        }
        #expect(await swift.presence.current == "here")
    }

    @Test func theRepositoryIsTheOneYouSetOrTheNestInDeveloper() {
        let defaults = UserDefaults(suiteName: "SwiftOnThisMacTests-\(UUID().uuidString)")!
        let home = URL(fileURLWithPath: "/Users/someone")
        #expect(SwiftOnThisMac.repository(defaults: defaults, home: home).path == "/Users/someone/Developer/nest")
        defaults.set("/Volumes/Work/nest", forKey: SwiftOnThisMac.repositoryKey)
        #expect(SwiftOnThisMac.repository(defaults: defaults, home: home).path == "/Volumes/Work/nest")
    }
}
