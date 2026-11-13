/// Finds shipping code that changes files, the look or settings in a file that never builds an undo for it.
public enum UndoCheck {
    /// Calls that change something on the Mac that a bird must be able to put back.
    static let changes = [
        ".moveItem(", ".removeItem(", ".trashItem(", ".copyItem(", ".replaceItem", ".setAttributes(",
        "setDesktopImageURL", "NSAppearance.current =", "\"defaults\", \"write\"", "osascript",
    ]
    /// What building an undo looks like (see `docs/event-bus.md`).
    static let undos = ["EventUndo(", "undo:"]

    /// One line per file that changes something without an undo.
    public static func problems(in diff: BranchDiff) -> [String] {
        diff.files.filter(\.isSource).compactMap { file in
            let changes = file.added.contains { line in Self.changes.contains(where: line.contains) }
            let undoes = file.added.contains { line in undos.contains(where: line.contains) }
            return changes && !undoes ? "\(file.path) changes files or settings without an undo" : nil
        }
    }
}
