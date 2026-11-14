import Foundation

/// What you tell Swift about one project, in plain words: add a task outright, run a task differently,
/// or ask for anything else and have it planned into small tested tasks.
public struct SwiftAsk: Sendable {
    /// The project you are talking about.
    public let project: SwiftProject
    /// Its queue.
    public let queue: TaskQueue
    /// What turns a plain request into tasks, or nil to only take tasks written out.
    public let planner: PlanPass?

    /// Talk about `project`, queueing into `queue` and planning with `planner`.
    public init(project: SwiftProject, queue: TaskQueue, planner: PlanPass?) {
        self.project = project
        self.queue = queue
        self.planner = planner
    }

    /// Acts on `message` and returns Swift's reply.
    public func answer(_ message: String) async throws -> String {
        if let (id, rest) = SwiftChat.retune(in: message),
           let wanted = SwiftChat.settings(in: rest, over: try await queue.task(id)?.run ?? project.defaults) {
            guard try await queue.task(id) != nil else { return "There's no \(id) in \(project.name)'s queue." }
            try await queue.setRun(wanted, for: id)
            return "\(id) will run on \(wanted.label)."
        }
        let override = SwiftChat.settings(in: message, over: project.defaults)
        switch SwiftChat.task(in: message) {
        case .task(let goal, let doneMeans):
            let id = SwiftChat.nextID(after: try await queue.tasks().map(\.id))
            try await queue.add(QueuedTask(id: id, goal: goal, doneMeans: doneMeans, run: override))
            return "Queued \(id): \(goal)."
        case .needsTest(let goal):
            return "A task needs a test before I spend on it. What does done mean for \"\(goal)\"?"
        case nil:
            break
        }
        guard let planner else { return "Tell me a task and its test: \"Add a task: … Done means: …\"" }
        let plan = try await planner.plan(message, as: "P", for: project.name)
        if let dropped = plan.dropped { return "I'd leave that one: \(dropped.trimmingCharacters(in: .init(charactersIn: ".")))." }
        var ids = try await queue.tasks().map(\.id)
        var queued: [String] = []
        for task in plan.tasks {
            let id = SwiftChat.nextID(after: ids)
            ids.append(id)
            try await queue.add(QueuedTask(id: id, goal: task.goal, doneMeans: task.doneMeans,
                                           needs: queued.last.map { [$0] } ?? [], source: .you, run: override))
            queued.append(id)
        }
        let count = queued.count == 1 ? "1 task" : "\(queued.count) tasks"
        return "Queued \(count) for \(project.name)\(override.map { ", on \($0.label)" } ?? ""): \(queued.joined(separator: ", "))."
    }
}
