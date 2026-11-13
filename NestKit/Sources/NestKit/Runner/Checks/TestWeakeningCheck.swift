/// Finds tests a branch removed, skipped or loosened.
public enum TestWeakeningCheck {
    /// Lines that hold a test or an assertion; removing one weakens the suite unless the same line comes back.
    static let assertions = ["@Test", "func test", "#expect", "#require", "XCTAssert", "XCTFail", "waitForExistence", "expectation("]
    /// Lines that switch a test off or excuse its failure.
    static let skips = [".disabled", "XCTSkip", "withKnownIssue", ".enabled(if"]

    /// One line per weakened test file, saying how.
    public static func problems(in diff: BranchDiff) -> [String] {
        diff.files.filter(\.isTest).compactMap { file in
            if file.isDeleted { return "\(file.path): a test file was deleted" }
            var comeBack = file.added.map(trimmed)
            let lost = file.removed.map(trimmed).filter { line in
                guard assertions.contains(where: line.contains) else { return false }
                if let moved = comeBack.firstIndex(of: line) {
                    comeBack.remove(at: moved)
                    return false
                }
                return true
            }
            let skipped = file.added.map(trimmed).filter { line in skips.contains(where: line.contains) }
            let found = lost + skipped
            return found.isEmpty ? nil : "\(file.path): weakened (\(found.joined(separator: "; ")))"
        }
    }

    private static func trimmed(_ line: String) -> String {
        line.trimmingCharacters(in: .whitespaces)
    }
}
