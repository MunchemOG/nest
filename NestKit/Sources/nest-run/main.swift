import Foundation
import NestKit

// The manual runner: one task from docs/queue.md becomes a tested branch while you watch.
//   scripts/run-task.sh S2-02          run the task, then the whole suite (UI tests take over the screen)
//   scripts/run-task.sh S2-02 unit     run the task, then every test except the UI tests

func stop(_ message: String) -> Never {
    FileHandle.standardError.write(Data("\(message)\n".utf8))
    exit(2)
}

let arguments = Array(CommandLine.arguments.dropFirst())
guard let id = arguments.first, arguments.count <= 2 else {
    stop("usage: nest-run <task id> [unit|all]")
}
let suite = arguments.count == 2 ? arguments[1] : "all"
guard suite == "unit" || suite == "all" else {
    stop("usage: nest-run <task id> [unit|all]")
}

let repository = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
guard let queue = try? QueueFile(contentsOf: repository.appending(path: "docs/queue.md")) else {
    stop("docs/queue.md not found; run this from the repository's root")
}
guard let task = queue.task(id) else {
    stop("\(id) is not in docs/queue.md")
}

let permission = ProcessInfo.processInfo.environment["NEST_RUN_PERMISSION_MODE"] ?? "bypassPermissions"
let runner = ManualRunner(
    repository: repository,
    session: ["claude", "-p", "--permission-mode", permission],
    tests: ["scripts/test.sh", suite],
    watch: { print($0) }
)

do {
    let outcome = try await runner.run(task)
    exit(outcome.isDone ? 0 : 1)
} catch ManualRunnerError.uncommittedChanges {
    stop("\(id): commit or stash your changes first; the runner will not switch branches over them")
} catch {
    stop("\(id): \(error)")
}
