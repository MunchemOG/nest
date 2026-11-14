import Foundation

/// A project you assign Swift: a git repository on this Mac and the rules Swift keeps there.
public struct SwiftProject: Sendable, Equatable, Codable, Identifiable {
    /// A short id, unique among your projects, such as `nest` or `swerve`.
    public var id: String
    /// The name you see.
    public var name: String
    /// The repository's folder.
    public var folder: String
    /// The branch work starts from and merges into.
    public var base: String
    /// The command that runs the project's tests, or nil if it has none.
    public var tests: [String]?
    /// Whether green work merges by itself; it only can when the project has tests.
    public var autoMerge: Bool
    /// Whether the Nest's own checks run (no weakened tests, no hard-coded design values, every action undoable).
    public var strictChecks: Bool
    /// Whether Swift brings in `docs/queue.md` from the base branch before each run.
    public var importsQueueFile: Bool
    /// How the project's tasks run unless a task says otherwise.
    public var defaults: RunSettings
    /// The project's share of your weekly cap, or nil for no limit of its own.
    public var share: Double?
    /// The tile colour you chose, or nil for the one its id gives it.
    public var tint: ProjectTile?

    /// A project with every field given.
    public init(id: String, name: String, folder: String, base: String = "main", tests: [String]? = nil, autoMerge: Bool = false,
                strictChecks: Bool = false, importsQueueFile: Bool = false, defaults: RunSettings = .everyday,
                share: Double? = nil) {
        self.id = id
        self.name = name
        self.folder = folder
        self.base = base
        self.tests = tests
        self.autoMerge = autoMerge
        self.strictChecks = strictChecks
        self.importsQueueFile = importsQueueFile
        self.defaults = defaults
        self.share = share
    }

    /// The colour of the project's tile.
    public var tile: ProjectTile {
        tint ?? ProjectTile.allCases[id.unicodeScalars.reduce(0) { $0 + Int($1.value) } % ProjectTile.allCases.count]
    }

    /// The letter on the project's tile.
    public var initial: String {
        let words = name.lowercased().hasPrefix("the ") ? name.dropFirst(4) : Substring(name)
        return words.first(where: { $0.isLetter || $0.isNumber }).map { String($0).uppercased() } ?? "?"
    }

    /// The repository's folder as a URL.
    public var url: URL { URL(fileURLWithPath: folder) }

    /// Whether green work merges by itself: auto-merge is on and there are tests to trust.
    public var merges: Bool { autoMerge && tests != nil }

    /// Where the project's queue is kept inside Swift's folder; the Nest keeps the queue it always had.
    public func queueFile(in swiftFolder: URL) -> URL {
        id == "nest" ? swiftFolder.appending(path: "queue.sqlite") : swiftFolder.appending(path: "projects/\(id)/queue.sqlite")
    }

    /// The Nest at `folder`, by its strictest rules.
    public static func nest(at folder: URL) -> SwiftProject {
        SwiftProject(id: "nest", name: "The Nest", folder: folder.path, tests: ["scripts/test.sh", "all"], autoMerge: true,
                     strictChecks: true, importsQueueFile: true)
    }

    /// The repository you picked at `folder` as a new project with gentle rules: no tests, no merging, one session.
    /// Its id comes from the folder's name and is never one of `taken`; its base is the branch it is on.
    public static func picked(_ folder: URL, taken: [String]) async throws -> SwiftProject {
        let branch = try await Shell().run(["git", "symbolic-ref", "--short", "HEAD"], in: folder)
        guard branch.succeeded else { throw SwiftProjectError.notARepository(folder.path) }
        let stem = folder.lastPathComponent.lowercased().map { $0.isLetter || $0.isNumber ? $0 : "-" }
        let root = String(stem).split(separator: "-").joined(separator: "-")
        let base = root.isEmpty ? "project" : root
        var id = base
        var number = 2
        while taken.contains(id) {
            id = "\(base)-\(number)"
            number += 1
        }
        return SwiftProject(id: id, name: folder.lastPathComponent, folder: folder.path,
                            base: branch.text.trimmingCharacters(in: .whitespacesAndNewlines))
    }

    /// The rules a project without its own `CLAUDE.md` is built by.
    public static let houseRules = """
        # Swift's house rules

        - Work only inside this repository.
        - Do only what the task's goal says; anything else worth doing goes under "Noticed".
        - Small commits on the task's branch, each one building. Message: "<task id>: <what changed>".
        - If the project has tests, add tests for what you add and never weaken an existing one.
        - Leave no TODO, commented-out code or debug print.
        - If the task is unclear, stop and say what is unclear.

        End with exactly this block:
        Result: done | held | unclear
        Did: <one sentence>
        Tests: <passed>/<total>, <new tests added>
        Files: <list>
        Noticed: <anything outside the task, or "nothing">
        Next: <what should come next>
        If held: <what failed and your best guess why>
        """
}
