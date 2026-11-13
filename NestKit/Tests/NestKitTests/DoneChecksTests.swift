import Foundation
import Testing
@testable import NestKit

struct DoneChecksTests {
    static let task = QueueTask(id: "T9-01", goal: "A change", doneMeans: "It is checked", needs: "nothing")

    static let summary = """
    echo "Result: done"
    echo "Did: Changed it."
    echo "Tests: 1/1, 0 new"
    echo "Files: some"
    echo "Noticed: nothing"
    echo "Next: none"
    """

    static let existingTest = """
    import Testing

    struct GreetingTests {
        @Test func saysHello() {
            #expect(greeting() == "hello")
            #expect(greeting().count == 5)
        }
    }

    """

    /// A repository whose main already has a test file, so a branch can weaken it.
    func repo() async throws -> TempRepo {
        let repo = try await TempRepo()
        let tests = repo.url.appending(path: "Tests/GreetingTests")
        try FileManager.default.createDirectory(at: tests, withIntermediateDirectories: true)
        try Self.existingTest.write(to: tests.appending(path: "GreetingTests.swift"), atomically: true, encoding: .utf8)
        try await repo.git("add", ".")
        try await repo.git("commit", "-q", "-m", "Add a test")
        return repo
    }

    func run(_ change: String, in repo: TempRepo) async throws -> RunOutcome {
        let session = """
        \(change)
        git add -A
        git commit -q -m "T9-01: Change it"
        \(Self.summary)
        """
        let runner = ManualRunner(repository: repo.url, session: try repo.script("session", session), tests: ["true"])
        return try await runner.run(Self.task)
    }

    @Test func aBranchThatWeakensATestIsHeld() async throws {
        let repo = try await repo()
        defer { repo.remove() }
        let outcome = try await run("sed -i '' '/count == 5/d' Tests/GreetingTests/GreetingTests.swift", in: repo)
        #expect(!outcome.isDone)
        #expect(outcome.testsPassed)
        #expect(outcome.held?.contains("Tests/GreetingTests/GreetingTests.swift") == true)
        #expect(outcome.held?.contains("weakened") == true)
    }

    @Test func aBranchWithAColourLiteralIsHeld() async throws {
        let repo = try await repo()
        defer { repo.remove() }
        let outcome = try await run("""
        mkdir -p NestApp/NestApp/Home
        printf 'import SwiftUI\\nstruct Badge: View {\\n    var body: some View { Circle().fill(Color(red: 1, green: 0, blue: 0)) }\\n}\\n' > NestApp/NestApp/Home/Badge.swift
        """, in: repo)
        #expect(!outcome.isDone)
        #expect(outcome.held?.contains("NestApp/NestApp/Home/Badge.swift") == true)
        #expect(outcome.held?.contains("Color(red: 1, green: 0, blue: 0)") == true)
    }

    @Test func aCleanBranchIsDone() async throws {
        let repo = try await repo()
        defer { repo.remove() }
        let outcome = try await run("""
        mkdir -p NestApp/NestApp/Home
        printf 'import SwiftUI\\nstruct Badge: View {\\n    var body: some View { Circle().fill(Color(NestColor.statusSuccess)).padding(NestSpace.s2) }\\n}\\n' > NestApp/NestApp/Home/Badge.swift
        printf '        #expect(greeting().isEmpty == false)\\n' >> Tests/GreetingTests/GreetingTests.swift
        """, in: repo)
        #expect(outcome.isDone, "\(outcome.held ?? "")")
    }

    // MARK: Each check on its own

    func diff(_ text: String) -> BranchDiff { BranchDiff(text: text) }

    @Test func readsAddedAndRemovedLinesPerFile() {
        let diff = diff("""
        diff --git a/Sources/A.swift b/Sources/A.swift
        index 1..2 100644
        --- a/Sources/A.swift
        +++ b/Sources/A.swift
        @@ -3 +3,2 @@
        -let a = 1
        +let a = 2
        +let b = 3
        diff --git a/Old.swift b/Old.swift
        deleted file mode 100644
        --- a/Old.swift
        +++ /dev/null
        @@ -1 +0,0 @@
        -gone
        """)
        #expect(diff.files.map(\.path) == ["Sources/A.swift", "Old.swift"])
        #expect(diff.files[0].added == ["let a = 2", "let b = 3"])
        #expect(diff.files[0].removed == ["let a = 1"])
        #expect(diff.files[1].isDeleted)
    }

    @Test func movingAnAssertionIsNotWeakening() {
        let diff = diff("""
        diff --git a/Tests/ATests.swift b/Tests/ATests.swift
        --- a/Tests/ATests.swift
        +++ b/Tests/ATests.swift
        @@ -3 +3 @@
        -        #expect(a == 1)
        @@ -9 +9 @@
        +    #expect(a == 1)
        """)
        #expect(TestWeakeningCheck.problems(in: diff).isEmpty)
    }

    @Test func skippingOrDeletingATestIsWeakening() {
        let diff = diff("""
        diff --git a/Tests/ATests.swift b/Tests/ATests.swift
        --- a/Tests/ATests.swift
        +++ b/Tests/ATests.swift
        @@ -3 +3 @@
        -    @Test func works() {
        +    @Test(.disabled()) func works() {
        diff --git a/NestApp/NestAppUITests/BUITests.swift b/NestApp/NestAppUITests/BUITests.swift
        deleted file mode 100644
        --- a/NestApp/NestAppUITests/BUITests.swift
        +++ /dev/null
        @@ -1 +0,0 @@
        -import XCTest
        """)
        let problems = TestWeakeningCheck.problems(in: diff)
        #expect(problems.count == 2)
        #expect(problems.contains { $0.contains("Tests/ATests.swift") })
        #expect(problems.contains { $0.contains("BUITests.swift") && $0.contains("deleted") })
    }

    @Test func designLiteralsAreFoundOnlyInViewCodeOutsideTheTokens() {
        let diff = diff("""
        diff --git a/NestApp/NestApp/Home/A.swift b/NestApp/NestApp/Home/A.swift
        --- a/NestApp/NestApp/Home/A.swift
        +++ b/NestApp/NestApp/Home/A.swift
        @@ -1 +1,6 @@
        +        .font(.system(size: 14))
        +        .padding(12)
        +        .frame(width: 320)
        +        .foregroundStyle(Color(hex: "#FF0000"))
        +        .animation(.easeInOut(duration: 0.3), value: on)
        +        VStack(spacing: 0) { }
        diff --git a/NestApp/NestApp/Tokens/NestColor.swift b/NestApp/NestApp/Tokens/NestColor.swift
        --- a/NestApp/NestApp/Tokens/NestColor.swift
        +++ b/NestApp/NestApp/Tokens/NestColor.swift
        @@ -1 +1 @@
        +    static let red = Color(red: 1, green: 0, blue: 0)
        diff --git a/NestKit/Sources/NestKit/Pets/PetWorld.swift b/NestKit/Sources/NestKit/Pets/PetWorld.swift
        --- a/NestKit/Sources/NestKit/Pets/PetWorld.swift
        +++ b/NestKit/Sources/NestKit/Pets/PetWorld.swift
        @@ -1 +1 @@
        +    let width: Double = 320
        """)
        let problems = DesignLiteralCheck.problems(in: diff)
        #expect(problems.count == 5)
        #expect(problems.allSatisfy { $0.hasPrefix("NestApp/NestApp/Home/A.swift") })
    }

    @Test func aSymlinkOutOfTheRepositoryIsCaught() {
        let diff = diff("""
        diff --git a/notes b/notes
        new file mode 120000
        --- /dev/null
        +++ b/notes
        @@ -0,0 +1 @@
        +../../Documents
        \\ No newline at end of file
        diff --git a/inside b/inside
        new file mode 120000
        --- /dev/null
        +++ b/inside
        @@ -0,0 +1 @@
        +docs/queue.md
        """)
        let problems = RepositoryBoundsCheck.problems(in: diff)
        #expect(problems == ["notes points outside the repository (../../Documents)"])
    }

    @Test func changingFilesWithoutAnUndoIsCaught() {
        let diff = diff("""
        diff --git a/NestKit/Sources/NestKit/Wren/Tidy.swift b/NestKit/Sources/NestKit/Wren/Tidy.swift
        --- /dev/null
        +++ b/NestKit/Sources/NestKit/Wren/Tidy.swift
        @@ -0,0 +1 @@
        +        try FileManager.default.moveItem(at: from, to: to)
        diff --git a/NestKit/Sources/NestKit/Wren/Sort.swift b/NestKit/Sources/NestKit/Wren/Sort.swift
        --- /dev/null
        +++ b/NestKit/Sources/NestKit/Wren/Sort.swift
        @@ -0,0 +1,2 @@
        +        try FileManager.default.moveItem(at: from, to: to)
        +        publish(undo: EventUndo(op: "file.move", args: ["from": .string(to.path), "to": .string(from.path)]))
        diff --git a/NestKit/Tests/NestKitTests/SortTests.swift b/NestKit/Tests/NestKitTests/SortTests.swift
        --- /dev/null
        +++ b/NestKit/Tests/NestKitTests/SortTests.swift
        @@ -0,0 +1 @@
        +        try FileManager.default.removeItem(at: folder)
        """)
        #expect(UndoCheck.problems(in: diff) == ["NestKit/Sources/NestKit/Wren/Tidy.swift changes files or settings without an undo"])
    }

    @Test func theApprovedViewCodeHasNoDesignLiterals() throws {
        let root = URL(fileURLWithPath: #filePath).deletingLastPathComponent().deletingLastPathComponent()
            .deletingLastPathComponent().deletingLastPathComponent()
        let views = root.appending(path: "NestApp/NestApp")
        let files = try #require(FileManager.default.enumerator(at: views, includingPropertiesForKeys: nil))
            .compactMap { $0 as? URL }.filter { $0.pathExtension == "swift" }
        #expect(!files.isEmpty)
        for file in files {
            let path = String(file.path.dropFirst(root.path.count + 1))
            let lines = try String(contentsOf: file, encoding: .utf8).split(separator: "\n").map(String.init)
            let whole = ChangedFile(path: path, added: lines, removed: [])
            #expect(DesignLiteralCheck.problems(in: BranchDiff(files: [whole])).isEmpty)
        }
    }
}
