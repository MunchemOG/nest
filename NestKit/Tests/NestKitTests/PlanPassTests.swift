import Foundation
import Testing
@testable import NestKit

struct PlanPassTests {
    static let idea = "Something so the downloads folder stops being a mess"

    /// A stand-in for Claude Code in plan mode: it records how it was started and answers with a plan.
    static func session(answering plan: String) -> String {
        """
        printf '%s\\n' "$@" > .git/plan-args.txt
        cat <<'PLAN'
        \(plan)
        PLAN
        """
    }

    static let threeTasks = """
    The smallest version sorts new downloads by kind.

    | id | goal | done_means | needs |
    | --- | --- | --- | --- |
    | P-01 | Read the downloads folder into a list of files with kinds | A test lists a temp folder's three files with their kinds | - |
    | P-02 | Choose a home folder for each kind | A test maps a PDF, an image and a CAD file to three folders | P-01 |
    | P-03 | Move a file to its home with an undo event | A test moves a temp file and its undo puts it back | P-02 |

    It touches only Wren's code.
    """

    func setUp(_ plan: String) async throws -> (TempRepo, TaskQueue, PlanPass) {
        let repo = try await TempRepo()
        let queue = try TaskQueue(at: repo.url.appending(path: ".git/queue.sqlite"))
        let pass = PlanPass(repository: repo.url, session: try repo.script("plan", Self.session(answering: plan)))
        return (repo, queue, pass)
    }

    @Test func aVagueIdeaComesBackAsThreeOrMoreSmallTasksWithTestsQueuedInOrder() async throws {
        let (repo, queue, pass) = try await setUp(Self.threeTasks)
        defer { repo.remove() }
        try await queue.add(QueuedTask(id: "S2-05", goal: "Yours", doneMeans: "Yours", priority: 0))

        let plan = try await pass.plan(Self.idea, as: "C1")
        try await pass.queue(plan, into: queue)

        #expect(plan.tasks.count >= 3)
        #expect(plan.tasks.allSatisfy { !$0.doneMeans.isEmpty })
        let tasks = try await queue.tasks()
        #expect(tasks.map(\.id) == ["S2-05", "C1-01", "C1-02", "C1-03"], "Crow's tasks go behind yours, in order")
        #expect(tasks[1].goal == "Read the downloads folder into a list of files with kinds")
        #expect(tasks[3].doneMeans == "A test moves a temp file and its undo puts it back")
        #expect(tasks.dropFirst().map(\.needs) == [[], ["C1-01"], ["C1-02"]])
        #expect(tasks.dropFirst().allSatisfy { $0.source == .crow })

        let arguments = try String(contentsOf: repo.url.appending(path: ".git/plan-args.txt"), encoding: .utf8)
        #expect(arguments.contains("--permission-mode\nplan\n"))
        #expect(arguments.contains(Self.idea))
        #expect(arguments.contains("done_means"))
    }

    @Test func crowsTasksGoBehindYourLowestPriority() async throws {
        let (repo, queue, pass) = try await setUp(Self.threeTasks)
        defer { repo.remove() }
        try await queue.add(QueuedTask(id: "S2-09", goal: "Yours", doneMeans: "Yours", priority: -4))
        try await pass.queue(try await pass.plan(Self.idea, as: "C2"), into: queue)
        #expect(try await queue.tasks().map(\.id) == ["S2-09", "C2-01", "C2-02", "C2-03"])
    }

    @Test func aPlanThatNeedsSomethingOutsideTheNestIsDroppedWithItsReason() async throws {
        let (repo, queue, pass) = try await setUp("Dropped: it needs a cloud sync service, and nothing leaves the Mac.")
        defer { repo.remove() }
        let plan = try await pass.plan("Sync my downloads to the cloud", as: "C3")
        #expect(plan.tasks.isEmpty)
        #expect(plan.dropped == "it needs a cloud sync service, and nothing leaves the Mac.")
        try await pass.queue(plan, into: queue)
        #expect(try await queue.tasks().isEmpty)
    }

    @Test func aPlanWithATaskThatHasNoTestIsRefused() async throws {
        let (repo, _, pass) = try await setUp("| P-01 | Do a thing |  | - |\n| P-02 | Do another | A test | P-01 |")
        defer { repo.remove() }
        await #expect(throws: PlanPassError.taskWithoutTest("P-01")) { try await pass.plan(Self.idea, as: "C4") }
    }

    @Test func aPlanWithNoTasksAndNoReasonIsRefused() async throws {
        let (repo, _, pass) = try await setUp("I think this is a nice idea.")
        defer { repo.remove() }
        await #expect(throws: PlanPassError.noPlan) { try await pass.plan(Self.idea, as: "C5") }
    }
}
