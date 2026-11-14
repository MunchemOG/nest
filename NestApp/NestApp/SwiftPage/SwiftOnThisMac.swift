import Foundation
import NestKit
import OSLog

/// Swift running itself on this Mac: once the menu bar switch says you're away, it looks at the queue every few minutes,
/// builds what is ready in the Nest's repository, merges green work and reports the night on Home.
final class SwiftOnThisMac {
    /// How long Swift waits between looks at the queue.
    nonisolated static let interval: Duration = .seconds(600)
    /// The defaults key that holds the repository's path, when it is not `~/Developer/nest`.
    nonisolated static let repositoryKey = "NestRepository"
    /// Swift's fixed rules; the learned forecast replaces the reserve once your days are logged.
    nonisolated static let rules = BudgetRules(reserve: 0.25)

    /// What Swift knows of whether you are at the Mac, heard only from the switch (and from Owl, once it exists).
    let presence = PresenceWatch()
    private let heard: AsyncStream<String>.Continuation
    private var shift: Task<Void, Never>?

    init() {
        let (stream, heard) = AsyncStream.makeStream(of: String.self)
        self.heard = heard
        Task { [presence] in
            for await to in stream {
                await presence.receive(.presenceChanged(to: to, was: ""))
            }
        }
    }

    /// Tells Swift you are `here` or `away`; it hears each in the order told.
    func hear(_ presence: String) {
        heard.yield(presence)
    }

    /// Starts Swift's shift, publishing its events with `publish`; it runs until the app quits.
    func start(publishing publish: @escaping @Sendable (NestEvent) async -> Void) {
        guard shift == nil else { return }
        let repository = Self.repository()
        let folder = SwiftPageModel.folder
        shift = Task { [presence] in
            let log = Logger(subsystem: "Nest", category: "swift")
            while !Task.isCancelled {
                do {
                    let runner = try await Self.runner(repository: repository, folder: folder, presence: presence, publish: publish)
                    _ = try await SwiftShift(runner: runner).tick()
                } catch {
                    log.error("Swift's shift stopped short: \(error)")
                }
                try? await Task.sleep(for: Self.interval)
            }
        }
    }

    /// The Nest's repository: the path in defaults, or `~/Developer/nest`.
    nonisolated static func repository(defaults: UserDefaults = .standard,
                                       home: URL = FileManager.default.homeDirectoryForCurrentUser) -> URL {
        defaults.string(forKey: repositoryKey).map { URL(fileURLWithPath: $0) } ?? home.appending(path: "Developer/nest")
    }

    /// The runner for one look at the queue, with the forecast learned from the days logged so far.
    nonisolated static func runner(
        repository: URL,
        folder: URL,
        presence: PresenceWatch,
        publish: @escaping @Sendable (NestEvent) async -> Void
    ) async throws -> QueueRunner {
        try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        let queue = try TaskQueue(at: folder.appending(path: "queue.sqlite"))
        let usage = try UsageLog(at: folder.appending(path: "usage.sqlite"))
        let forecast = UsageForecast(history: try await usage.yourUse())
        let log = Logger(subsystem: "Nest", category: "swift")
        let suite = ["scripts/test.sh", "all"]
        return QueueRunner(
            queue: queue,
            runner: ManualRunner(repository: repository, session: session, tests: suite, watch: { log.info("\($0)") }),
            merger: AutoMerge(repository: repository),
            mainTests: suite,
            publish: publish,
            usageLog: usage,
            budget: Budget(rules: rules, log: usage, forecast: forecast),
            presence: presence
        )
    }

    /// The command that starts one Claude Code session; the prompt arrives as `$0`. Apps get a bare PATH,
    /// so the places Claude Code installs to are added first.
    nonisolated static let session = [
        "/bin/sh", "-c",
        #"PATH="$HOME/.local/bin:/opt/homebrew/bin:/usr/local/bin:$PATH" exec claude -p --output-format stream-json --verbose --permission-mode bypassPermissions "$0""#,
    ]
}
