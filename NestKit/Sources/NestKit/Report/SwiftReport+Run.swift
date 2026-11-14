extension SwiftReport {
    /// The report for a run of the queue, each task ending as the queue left it: done is merged, held after a
    /// green build is rolled back, and held otherwise stayed on its branch.
    public init(run: QueueRun, states: [String: QueueState], usage: ReportedUsage) {
        let tasks = run.outcomes.map { outcome -> ReportedTask in
            let id = outcome.task.id
            if let held = outcome.held {
                return ReportedTask(id: id, ending: .held, testsAdded: 0, why: "\(id) was held: \(held)")
            }
            guard states[id] == .done else {
                return ReportedTask(id: id, ending: .fail, testsAdded: 0, why: "\(id) was rolled back: \(Self.rollbackWhy)")
            }
            return ReportedTask(id: id, ending: .ok, testsAdded: AutoMerge.testsAdded(from: outcome.summary?.tests))
        }
        let merged = run.outcomes.filter { $0.held == nil && states[$0.task.id] == .done }
        let counted = (merged.isEmpty ? run.outcomes : merged).compactMap { Self.passing(in: $0.summary?.tests) }
        self.init(tasks: tasks, testsPassing: counted.last ?? 0, healthy: true, usage: usage)
    }

    /// The rollback's reason as it reads mid-sentence.
    private static var rollbackWhy: String {
        let reason = QueueRunner.rollbackReason
        return (reason.prefix(1).lowercased() + reason.dropFirst()).trimmingCharacters(in: ["."])
    }

    /// The passing count in a summary block's `Tests:` line, such as 304 in "304/304, 19 new".
    private static func passing(in line: String?) -> Int? {
        line?.firstMatch(of: /(\d+)\/\d+/).flatMap { Int($0.1) }
    }
}
