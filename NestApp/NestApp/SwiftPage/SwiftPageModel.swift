import Foundation
import NestKit
import Observation

/// Swift's page in its close-up: a chat that can add tasks, tonight's queue, usage and the boundaries it keeps.
@MainActor
@Observable
final class SwiftPageModel {
    let queue: TaskQueue
    let rules: BudgetRules
    let log: UsageLog?

    /// The chat so far, oldest first.
    private(set) var messages: [ChatMessage] = []
    /// Tasks waiting or being built, in the order Swift will take them.
    private(set) var tonight: [QueuedTask] = []
    /// The latest limits Claude reported, if any run was logged.
    private(set) var limits: LimitSnapshot?

    init(queue: TaskQueue, rules: BudgetRules, log: UsageLog? = nil) {
        self.queue = queue
        self.rules = rules
        self.log = log
    }

    /// Where Swift keeps its queue and usage log on this Mac.
    nonisolated static var folder: URL { URL.applicationSupportDirectory.appending(path: "Nest/Swift") }

    /// Swift's page on this Mac, with its queue and usage log in the app's own support folder.
    static func onThisMac() throws -> SwiftPageModel {
        try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        return SwiftPageModel(queue: try TaskQueue(at: folder.appending(path: "queue.sqlite")),
                              rules: SwiftOnThisMac.rules,
                              log: try UsageLog(at: folder.appending(path: "usage.sqlite")))
    }

    /// Reads the queue and the latest limits again.
    func refresh() async {
        tonight = ((try? await queue.tasks()) ?? []).filter { $0.state == .queued || $0.state == .claimed }
        limits = (try? await log?.entries())?.last(where: { $0.limits != nil })?.limits
    }

    /// Sends `text` to Swift; a task with a test is queued, one without gets a question.
    func send(_ text: String) async {
        messages.append(ChatMessage(id: UUID().uuidString, sender: .you, text: text))
        let reply: String
        switch SwiftChat.task(in: text) {
        case .task(let goal, let doneMeans):
            let ids = ((try? await queue.tasks()) ?? []).map(\.id)
            let id = SwiftChat.nextID(after: ids)
            do {
                try await queue.add(QueuedTask(id: id, goal: goal, doneMeans: doneMeans))
                reply = "Queued \(id): \(goal)."
            } catch {
                reply = "I couldn't queue that: \(error.localizedDescription)"
            }
        case .needsTest(let goal):
            reply = "A task needs a test before I spend on it. What does done mean for \"\(goal)\"?"
        case nil:
            reply = "Tell me a task and its test: \"Add a task: … Done means: …\""
        }
        messages.append(ChatMessage(id: UUID().uuidString, sender: .bird(.swift), text: reply))
        await refresh()
    }

    /// How much of the limits is used, in one line.
    var usage: String {
        guard let limits else { return "No runs logged yet." }
        return "\(Self.percent(limits.weekly)) of the week used · \(Self.percent(limits.fiveHour)) of the five hours"
    }

    /// What Swift keeps to, one line each.
    var boundaries: [String] {
        ["Keeps \(Self.percent(rules.reserve)) of the week back for you."]
            + rules.blocked.map { "Never runs in \($0.reason.lowercased()), \(Self.clock($0.from))–\(Self.clock($0.to))." }
            + ["Stands down when you arrive.", "Merges only when every test passes."]
    }

    private static func percent(_ share: Double) -> String { "\(Int((share * 100).rounded()))%" }
    private static func clock(_ minutes: Int) -> String { String(format: "%02d:%02d", minutes / 60, minutes % 60) }
}
