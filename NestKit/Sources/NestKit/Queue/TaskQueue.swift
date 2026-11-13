import Foundation

/// Swift's task queue, kept in an SQLite file on this Mac: tasks are added, claimed in order and finished.
public actor TaskQueue {
    private let database: SQLiteDatabase

    /// The queue stored in the file at `url`, created empty if the file is new.
    public init(at url: URL) throws {
        database = try SQLiteDatabase(at: url)
        try database.execute("""
            CREATE TABLE IF NOT EXISTS tasks (
                id TEXT PRIMARY KEY,
                goal TEXT NOT NULL,
                done_means TEXT NOT NULL,
                priority INTEGER NOT NULL,
                needs TEXT NOT NULL,
                source TEXT NOT NULL,
                state TEXT NOT NULL
            )
            """)
    }

    /// Adds `task` at the back of its priority, as given.
    public func add(_ task: QueuedTask) throws {
        do {
            try database.execute(
                "INSERT INTO tasks (id, goal, done_means, priority, needs, source, state) VALUES (?, ?, ?, ?, ?, ?, ?)",
                [.text(task.id), .text(task.goal), .text(task.doneMeans), .integer(task.priority),
                 .text(task.needs.joined(separator: ",")), .text(task.source.rawValue), .text(task.state.rawValue)]
            )
        } catch let error as SQLiteError where error.code == Self.primaryKeyTaken {
            throw TaskQueueError.duplicate(task.id)
        }
    }

    /// Every task, in the order they would be built: highest priority first, then the order they were added.
    public func tasks() throws -> [QueuedTask] {
        try database.rows("SELECT id, goal, done_means, priority, needs, source, state FROM tasks ORDER BY priority DESC, rowid")
            .compactMap(Self.task)
    }

    /// The task with this id, if the queue has one.
    public func task(_ id: String) throws -> QueuedTask? {
        try tasks().first { $0.id == id }
    }

    /// Takes the first queued task whose needs are all done and marks it claimed, or returns nil if none is ready.
    /// A need that is not in the queue does not block: it was finished before the queue knew of it.
    public func claim() throws -> QueuedTask? {
        try database.writing {
            let all = try tasks()
            let states = Dictionary(uniqueKeysWithValues: all.map { ($0.id, $0.state) })
            guard let next = all.first(where: { task in
                task.state == .queued && task.needs.allSatisfy { states[$0].map { $0 == .done } ?? true }
            }) else { return nil }
            try database.execute("UPDATE tasks SET state = ? WHERE id = ?", [.text(QueueState.claimed.rawValue), .text(next.id)])
            return QueuedTask(id: next.id, goal: next.goal, doneMeans: next.doneMeans, priority: next.priority,
                              needs: next.needs, source: next.source, state: .claimed)
        }
    }

    /// Marks a claimed task done or held.
    public func finish(_ id: String, as state: QueueState) throws {
        guard state == .done || state == .held else { throw TaskQueueError.notAnEnd(state) }
        try database.execute(
            "UPDATE tasks SET state = ? WHERE id = ? AND state = ?",
            [.text(state.rawValue), .text(id), .text(QueueState.claimed.rawValue)]
        )
        guard database.changes == 1 else { throw TaskQueueError.notClaimed(id) }
    }

    private static func task(_ row: [SQLiteValue]) -> QueuedTask? {
        guard row.count == 7, let id = row[0].text, let goal = row[1].text, let doneMeans = row[2].text,
              let priority = row[3].integer, let needs = row[4].text,
              let source = row[5].text.flatMap(QueueSource.init), let state = row[6].text.flatMap(QueueState.init)
        else { return nil }
        return QueuedTask(id: id, goal: goal, doneMeans: doneMeans, priority: priority,
                          needs: needs.split(separator: ",").map(String.init), source: source, state: state)
    }

    /// SQLite's extended code for a primary key that is already taken.
    private static let primaryKeyTaken: Int32 = 1555
}
