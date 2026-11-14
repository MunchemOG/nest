import Foundation
import Testing
@testable import NestKit

struct SwiftAskTests {
    static let sonnet = RunSettings.everyday

    func setUp(plan: String = PlanPassTests.threeTasks) async throws -> (TempRepo, TaskQueue, SwiftAsk) {
        let repo = try await TempRepo()
        let queue = try TaskQueue(at: repo.url.appending(path: ".git/queue.sqlite"))
        let project = SwiftProject(id: "robotics", name: "Robotics", folder: repo.url.path, defaults: Self.sonnet)
        let planner = PlanPass(repository: repo.url, session: try repo.script("plan", PlanPassTests.session(answering: plan)))
        return (repo, queue, SwiftAsk(project: project, queue: queue, planner: planner))
    }

    @Test func wordsInAMessageSetHowItsTasksRun() {
        #expect(SwiftChat.settings(in: "sort my downloads", over: Self.sonnet) == nil)
        #expect(SwiftChat.settings(in: "sort my downloads on Opus, max", over: Self.sonnet)
                == RunSettings(model: .opus, effort: .max, subagents: false))
        #expect(SwiftChat.settings(in: "do it with agents", over: Self.sonnet)
                == RunSettings(model: .sonnet, effort: .high, subagents: true))
        #expect(SwiftChat.settings(in: "Fable, extra high effort, solo", over: RunSettings.deepest)
                == RunSettings(model: .fable, effort: .xhigh, subagents: false))
        #expect(SwiftChat.settings(in: "quick one on haiku, low effort", over: Self.sonnet)
                == RunSettings(model: .haiku, effort: .low, subagents: false))
        #expect(SwiftChat.settings(in: "high priority please", over: Self.sonnet) == nil)
    }

    @Test func aPlainRequestIsPlannedIntoTasksThatCarryTheOverride() async throws {
        let (repo, queue, ask) = try await setUp()
        defer { repo.remove() }
        try await queue.add(QueuedTask(id: "Y-01", goal: "Earlier", doneMeans: "earlier", state: .done))

        let reply = try await ask.answer("Make the downloads folder stop being a mess, on opus max with agents")

        let tasks = try await queue.tasks().filter { $0.state == .queued }
        #expect(tasks.map(\.id) == ["Y-02", "Y-03", "Y-04"])
        #expect(tasks.map(\.needs) == [[], ["Y-02"], ["Y-03"]])
        #expect(tasks.allSatisfy { $0.source == .you })
        #expect(tasks.allSatisfy { $0.run == RunSettings(model: .opus, effort: .max, subagents: true) })
        #expect(tasks.first?.goal == "Read the downloads folder into a list of files with kinds")
        #expect(reply == "Queued 3 tasks for Robotics, on Opus · Max · agents: Y-02, Y-03, Y-04.")
        let arguments = try String(contentsOf: repo.url.appending(path: ".git/plan-args.txt"), encoding: .utf8)
        #expect(arguments.contains("Plan this rough idea for Robotics"))
    }

    @Test func aRequestTheyWouldDropIsExplained() async throws {
        let (repo, queue, ask) = try await setUp(plan: "Dropped: it needs a cloud service.")
        defer { repo.remove() }
        #expect(try await ask.answer("Sync my photos to the cloud") == "I'd leave that one: it needs a cloud service.")
        #expect(try await queue.tasks().isEmpty)
    }

    @Test func doingOneTaskDifferentlyChangesOnlyThatTask() async throws {
        let (repo, queue, ask) = try await setUp()
        defer { repo.remove() }
        try await queue.add(QueuedTask(id: "Y-03", goal: "Three", doneMeans: "three"))
        try await queue.add(QueuedTask(id: "Y-04", goal: "Four", doneMeans: "four"))

        let reply = try await ask.answer("do Y-03 on opus")

        #expect(try await queue.task("Y-03")?.run == RunSettings(model: .opus, effort: .high, subagents: false))
        #expect(try await queue.task("Y-04")?.run == nil)
        #expect(reply == "Y-03 will run on Opus · High.")
    }

    @Test func aTaskThatIsNotQueuedCannotBeChanged() async throws {
        let (repo, _, ask) = try await setUp()
        defer { repo.remove() }
        #expect(try await ask.answer("run Y-09 on fable") == "There's no Y-09 in Robotics's queue.")
    }

    @Test func addingATaskOutrightStillWorksAndTakesTheOverride() async throws {
        let (repo, queue, ask) = try await setUp()
        defer { repo.remove() }
        let reply = try await ask.answer("Add a task: log the auton path on haiku. Done means: a test reads the log back")
        #expect(reply == "Queued Y-01: Log the auton path on haiku.")
        #expect(try await queue.task("Y-01")?.run == RunSettings(model: .haiku, effort: .high, subagents: false))
        #expect(try await ask.answer("Add a task: make it nicer")
                == "A task needs a test before I spend on it. What does done mean for \"Make it nicer\"?")
    }
}
