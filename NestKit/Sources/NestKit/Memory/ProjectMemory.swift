import Foundation

/// A project's memory brief, kept in the repository in `.nest/memory/`: an index and one file per section.
/// Every task starts from it instead of re-reading the repository, and leaves it true for the next.
public struct ProjectMemory: Sendable, Equatable {
    /// `README.md`: what the brief is and how it was built.
    public let index: String
    /// The sections, by name.
    public let sections: [MemorySection]

    /// The folder the brief lives in, inside the repository.
    public static let folder = ".nest/memory"

    /// The brief as it stands at `ref` in `repository`, or nil if there is none.
    public static func read(in repository: URL, at ref: String) async throws -> ProjectMemory? {
        let shell = Shell()
        let listed = try await shell.run(["git", "ls-tree", "--name-only", "\(ref):\(folder)"], in: repository)
        guard listed.succeeded else { return nil }
        var index = ""
        var sections: [MemorySection] = []
        for file in listed.text.split(separator: "\n").map(String.init).sorted() where file.hasSuffix(".md") {
            let shown = try await shell.run(["git", "show", "\(ref):\(folder)/\(file)"], in: repository)
            guard shown.succeeded else { continue }
            if file == "README.md" {
                index = shown.text
            } else {
                sections.append(MemorySection(name: String(file.dropLast(3)), text: shown.text))
            }
        }
        return ProjectMemory(index: index, sections: sections)
    }

    /// The brief as a session reads it: how to use it, then the index and every section.
    public var prompt: String {
        (["# Project memory (\(Self.folder))", Self.keepingItTrue, index]
            + sections.map { "## \($0.name).md (covers: \($0.covers.joined(separator: ", ")))\n\n\($0.body)" })
            .joined(separator: "\n\n")
    }

    /// What every session is told about the brief.
    public static let keepingItTrue = """
        This is the project's memory brief. Use it as your map instead of re-reading the whole repository, \
        but trust the code wherever the two disagree. Before your last commit, bring the brief up to date in \(folder)/: \
        rewrite every section your change made untrue, delete lines and whole sections that no longer hold, add what a later \
        session would need, and keep each section's `covers:` list naming the paths it describes. Commit the brief with your \
        work, in or after your last code commit, so it matches the code.
        """

    /// The sections at `ref` whose covered paths changed after the section was last written.
    public static func stale(in repository: URL, at ref: String) async throws -> [String] {
        guard let memory = try await read(in: repository, at: ref) else { return [] }
        let shell = Shell()
        var stale: [String] = []
        for section in memory.sections where !section.covers.isEmpty {
            let changed = try await shell.run(["git", "log", "-1", "--format=%H", ref, "--"] + section.covers, in: repository)
            let code = changed.text.trimmingCharacters(in: .whitespacesAndNewlines)
            guard changed.succeeded, !code.isEmpty else { continue }
            let written = try await shell.run(["git", "log", "-1", "--format=%H", ref, "--", "\(folder)/\(section.name).md"],
                                              in: repository)
            let note = written.text.trimmingCharacters(in: .whitespacesAndNewlines)
            let after = try await shell.run(["git", "merge-base", "--is-ancestor", code, note], in: repository)
            if note.isEmpty || !after.succeeded { stale.append(section.name) }
        }
        return stale
    }

    /// Keeps `project`'s brief alive: queues its first build if it has none, or a rebuild once more than half of it is stale.
    /// Returns the queued task's id, or nil if nothing was needed or a build is already waiting.
    @discardableResult
    public static func keep(_ project: SwiftProject, queue: TaskQueue) async throws -> String? {
        guard try await !buildWaiting(in: queue) else { return nil }
        guard let memory = try await read(in: project.url, at: project.base) else {
            return try await add(build(rebuild: false), for: project, to: queue)
        }
        let stale = try await stale(in: project.url, at: project.base)
        guard stale.count * 2 > memory.sections.count else { return nil }
        return try await add(build(rebuild: true), for: project, to: queue)
    }

    /// Queues a full rebuild of `project`'s brief now, unless one is already waiting.
    @discardableResult
    public static func rebuild(_ project: SwiftProject, queue: TaskQueue) async throws -> String? {
        guard try await !buildWaiting(in: queue) else { return nil }
        return try await add(build(rebuild: true), for: project, to: queue)
    }

    private static func buildWaiting(in queue: TaskQueue) async throws -> Bool {
        try await queue.tasks().contains { $0.id.hasPrefix("M-") && ($0.state == .queued || $0.state == .claimed) }
    }

    private static func add(_ goal: String, for project: SwiftProject, to queue: TaskQueue) async throws -> String {
        let tasks = try await queue.tasks()
        let used = tasks.compactMap { $0.id.firstMatch(of: /^M-(\d+)$/).flatMap { Int($0.1) } }
        let id = "M-" + String(format: "%02d", (used.max() ?? 0) + 1)
        try await queue.add(QueuedTask(id: id, goal: goal, doneMeans: doneMeans,
                                       priority: (tasks.map(\.priority).max() ?? 0) + 1, run: project.memory))
        return id
    }

    private static func build(rebuild: Bool) -> String {
        (rebuild ? "Rebuild the project's memory brief from the code as it is now. " : "Build the project's memory brief. ")
            + """
            Read the whole repository, as deeply as you need; this is the one session that does. Write \(folder)/README.md \
            (what the project is, how it is built, tested and run, the model you are, today's date, and a list of the sections) \
            and one \(folder)/<section>.md per part of the project: its structure, conventions, decisions and why, open work, \
            and the traps a newcomer would fall into. Start each section with front matter holding `covers: [paths]`, the files \
            and folders it describes. Be complete and exact: a later session must be able to work from the brief without \
            re-reading the code, so lose nothing that matters. Delete sections and lines that are no longer true. Change no code.
            """
    }

    private static let doneMeans = "\(folder)/README.md lists every section, and every section names the paths it covers"
}
