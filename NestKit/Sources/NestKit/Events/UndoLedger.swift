/// Works out which events are currently reversed, following undo and redo chains.
public struct UndoLedger: Sendable {
    private var undoneIDs: Set<String> = []

    /// The ledger after `events`, in the order they happened.
    public init(events: some Sequence<NestEvent>) {
        var reversedBy: [String: [String]] = [:]
        for event in events where event.kind == .undo {
            if case .string(let target) = event.data["target"] {
                reversedBy[target, default: []].append(event.id)
            }
        }
        var memo: [String: Bool] = [:]
        func isUndone(_ id: String) -> Bool {
            if let known = memo[id] { return known }
            memo[id] = false
            let undone = (reversedBy[id] ?? []).contains { !isUndone($0) }
            memo[id] = undone
            return undone
        }
        for id in reversedBy.keys where isUndone(id) {
            undoneIDs.insert(id)
        }
    }

    /// Whether the event with `id` is reversed right now.
    public func isUndone(_ id: String) -> Bool {
        undoneIDs.contains(id)
    }
}
