import Foundation
import NestKit
import OSLog

/// Swift running itself on this Mac: once the menu bar switch says you're away, it looks at every project's queue every few
/// minutes, builds what is ready in each project's folder by its rules, merges green work and reports the night on Home.
final class SwiftOnThisMac {
    /// How long Swift waits between looks at the queue.
    nonisolated static let interval: Duration = .seconds(600)
    /// The defaults key that holds the repository's path, when it is not `~/Developer/nest`.
    nonisolated static let repositoryKey = "NestRepository"
    /// The reserve kept back for you until the learned forecast has your days logged.
    nonisolated static let reserve = 0.25
    /// Swift's rules before you set any limits; the learned forecast replaces the reserve once your days are logged.
    nonisolated static let rules = SwiftLimits.standard.rules(reserve: reserve)

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
        let store = Self.settings()
        let folder = SwiftPageModel.folder
        shift = Task { [presence] in
            let log = Logger(subsystem: "Nest", category: "swift")
            while !Task.isCancelled {
                do {
                    let night = SwiftNight(settings: try store.load(), folder: folder, session: Self.session, presence: presence,
                                           publish: publish, reserve: Self.reserve, watch: { log.info("\($0)") })
                    for run in await night.tick() {
                        if let error = run.error { log.error("Swift's shift on \(run.project) stopped short: \(error)") }
                    }
                } catch {
                    log.error("Swift could not read its settings: \(error)")
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

    /// Where your limits and projects are saved; until you save, they hold the Nest at its repository.
    nonisolated static func settings(defaults: UserDefaults = .standard) -> SwiftSettingsStore {
        SwiftSettingsStore(at: SwiftPageModel.folder.appending(path: "settings.json"), nest: repository(defaults: defaults))
    }

    /// The runner for one look at the Nest's queue, with the forecast learned from the days logged so far.
    nonisolated static func runner(
        repository: URL,
        folder: URL,
        presence: PresenceWatch,
        publish: @escaping @Sendable (NestEvent) async -> Void
    ) async throws -> QueueRunner {
        try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        let log = Logger(subsystem: "Nest", category: "swift")
        let nest = SwiftProject.nest(at: repository)
        let night = SwiftNight(settings: SwiftSettings(limits: .standard, projects: [nest]), folder: folder, session: session,
                               presence: presence, publish: publish, reserve: reserve, watch: { log.info("\($0)") })
        return try await night.runner(for: nest)
    }

    /// The command that starts one Claude Code session; the run settings and the prompt that follow it all reach `claude`.
    /// Apps get a bare PATH, so the places Claude Code installs to are added first.
    nonisolated static let session = [
        "/bin/sh", "-c",
        #"PATH="$HOME/.local/bin:/opt/homebrew/bin:/usr/local/bin:$PATH" exec claude -p --output-format stream-json --verbose --permission-mode bypassPermissions "$@""#,
        "claude",
    ]
}
