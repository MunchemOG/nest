import Foundation
import NestKit
import Testing
@testable import NestApp

@MainActor
struct SwiftCockpitTests {
    func temp() throws -> URL {
        let url = FileManager.default.temporaryDirectory.appending(path: "SwiftCockpitTests-\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
        return url
    }

    /// A git repository in a temp folder with one commit on main.
    func repository(in folder: URL, named name: String) throws -> URL {
        let url = folder.appending(path: name)
        try FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
        try "A project.\n".write(to: url.appending(path: "README.md"), atomically: true, encoding: .utf8)
        for arguments in [["init", "-q", "-b", "main"], ["config", "user.name", "Nest Tests"],
                          ["config", "user.email", "tests@nest.invalid"], ["config", "commit.gpgsign", "false"],
                          ["add", "."], ["commit", "-q", "-m", "Start"]] {
            let git = Process()
            git.executableURL = URL(fileURLWithPath: "/usr/bin/git")
            git.arguments = arguments
            git.currentDirectoryURL = url
            try git.run()
            git.waitUntilExit()
        }
        return url
    }

    /// A cockpit over a temp Swift folder, with the Nest at `nest` and a usage log where two tasks used 10% of the week each.
    func cockpit(nest: URL? = nil) async throws -> (SwiftPageModel, URL) {
        let folder = try temp()
        let log = try UsageLog(at: folder.appending(path: "usage.sqlite"))
        try await log.record(task: "Y-01", project: "nest",
                             usage: try #require(SessionUsage(output: Self.stream(cost: 1, weekly: 0.1))),
                             started: Self.at(9, 0), ended: Self.at(9, 30))
        try await log.record(task: "Y-02", project: "nest",
                             usage: try #require(SessionUsage(output: Self.stream(cost: 1, weekly: 0.2))),
                             started: Self.at(9, 31), ended: Self.at(10, 0))
        let store = SwiftSettingsStore(at: folder.appending(path: "settings.json"), nest: nest ?? folder.appending(path: "nest"))
        let page = try SwiftPageModel(store: store, folder: folder, log: log, now: { Self.at(11, 0) })
        await page.refresh()
        return (page, folder)
    }

    nonisolated static func at(_ hour: Int, _ minute: Int) -> Date {
        Date(timeIntervalSince1970: 1_794_600_000 + Double(hour * 3600 + minute * 60))
    }

    nonisolated static func stream(cost: Double, weekly: Double) -> String {
        """
        {"type":"rate_limit_event","rate_limit_info":{"status":"allowed","unifiedWindows":{"five_hour":{"utilization":0.5,"resetsAt":1794625200,"status":"allowed"},"seven_day":{"utilization":\(weekly),"resetsAt":1794693600,"status":"allowed"}}}}
        {"type":"result","subtype":"success","total_cost_usd":\(cost),"result":"Result: done","usage":{"input_tokens":3,"output_tokens":200},"modelUsage":{"claude-sonnet-5-5":{"costUSD":\(cost)}}}
        """
    }

    @Test func movingTheCapChangesTheTasksLeftAndIsSaved() async throws {
        let (page, folder) = try await cockpit()
        defer { try? FileManager.default.removeItem(at: folder) }
        #expect(page.limits.weeklyCap == 0.75)
        #expect(page.tasksLeft == 5)
        #expect(page.tasksLeftLine == "About 5 tasks left this week")

        await page.setWeeklyCap(0.4)

        #expect(page.tasksLeft == 2)
        #expect(page.tasksLeftLine == "About 2 tasks left this week")
        #expect(try page.store?.load().limits.weeklyCap == 0.4)

        await page.setFiveHourCap(0.6)
        #expect(try page.store?.load().limits.fiveHourCap == 0.6)
    }

    @Test func pickingAFolderAddsAProjectAndChoosesIt() async throws {
        let (page, folder) = try await cockpit()
        defer { try? FileManager.default.removeItem(at: folder) }
        let repo = try repository(in: folder, named: "Swerve Drive")

        await page.addProject(at: repo)

        #expect(page.projects.map(\.id) == ["nest", "swerve-drive"])
        #expect(page.project.id == "swerve-drive")
        #expect(page.project.name == "Swerve Drive")
        #expect(try page.store?.load().projects.map(\.id) == ["nest", "swerve-drive"])
        #expect(page.messages.last?.text == "Added Swerve Drive. Tell me what to build there.")
    }

    @Test func aFolderThatIsNotARepositoryIsExplained() async throws {
        let (page, folder) = try await cockpit()
        defer { try? FileManager.default.removeItem(at: folder) }
        let plain = folder.appending(path: "Notes")
        try FileManager.default.createDirectory(at: plain, withIntermediateDirectories: true)

        await page.addProject(at: plain)

        #expect(page.projects.map(\.id) == ["nest"])
        #expect(page.messages.last?.text == "Notes isn't a git repository yet, so I can't work there safely. Run git init in it first.")
    }

    @Test func switchingModelSavesTheProjectsDefault() async throws {
        let (page, folder) = try await cockpit()
        defer { try? FileManager.default.removeItem(at: folder) }

        page.setModel(.opus)
        page.setEffort(.max)
        page.setSubagents(true)

        #expect(page.project.defaults == RunSettings(model: .opus, effort: .max, subagents: true))
        #expect(try page.store?.load().projects.first?.defaults == RunSettings(model: .opus, effort: .max, subagents: true))
    }

    @Test func eachProjectKeepsItsOwnRulesAndQueue() async throws {
        let (page, folder) = try await cockpit()
        defer { try? FileManager.default.removeItem(at: folder) }
        let repo = try repository(in: folder, named: "physics")
        await page.addProject(at: repo)

        page.setTests("make test")
        page.setAutoMerge(true)
        await page.send("Add a task: plot the data. Done means: a test sees the plot")

        #expect(page.project.tests == ["/bin/sh", "-c", "make test"])
        #expect(page.project.autoMerge)
        #expect(page.testsLine == "make test")
        #expect(page.tonight.map(\.id) == ["Y-01"])
        await page.select("nest")
        #expect(page.tonight.isEmpty)
        #expect(page.project.tests == ["scripts/test.sh", "all"])
        #expect(page.testsLine == "scripts/test.sh all")
    }

    @Test func aTaskCanRunDifferentlyFromItsRow() async throws {
        let (page, folder) = try await cockpit()
        defer { try? FileManager.default.removeItem(at: folder) }
        await page.send("Add a task: tidy. Done means: tidy")

        await page.setRun(RunSettings(model: .fable, effort: .xhigh, subagents: false), for: "Y-01")
        #expect(page.tonight.first?.run == RunSettings(model: .fable, effort: .xhigh, subagents: false))
        await page.setRun(nil, for: "Y-01")
        #expect(page.tonight.first?.run == nil)
    }

    @Test func memoryShowsWhatTheBriefHoldsAndARebuildCanBeAsked() async throws {
        let folder = try temp()
        defer { try? FileManager.default.removeItem(at: folder) }
        let nest = try repository(in: folder, named: "nest")
        let (page, swift) = try await cockpit(nest: nest)
        defer { try? FileManager.default.removeItem(at: swift) }
        #expect(page.memoryLine == "No memory yet. The next night builds it on Opus · Max · agents.")

        await page.rebuildMemory()

        #expect(page.tonight.first?.id == "M-01")
        #expect(page.tonight.first?.run == .deepest)
        page.setMemoryModel(.fable)
        #expect(page.project.memory.model == .fable)
    }
}
