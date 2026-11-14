import Foundation
import NestKit
import Observation

/// One live Claude Code session in the project you chose, shared by Swift's close-up and the small Swift.
/// It only drives Claude Code; everything it shows is what Claude Code said.
@MainActor
@Observable
final class SwiftSessionModel {
    /// Your projects and limits.
    let page: SwiftPageModel
    /// Claude Code's own record of past sessions.
    let history: ClaudeHistory
    private let command: [String]

    /// What you see of the session.
    private(set) var transcript: SessionTranscript
    /// The session's id once Claude Code has given it, for resuming.
    private(set) var sessionID: String?
    /// The title of the session you resumed, or nil for a new one.
    private(set) var title: String?
    /// Claude Code's slash commands.
    private(set) var commands: [SlashCommand] = []
    /// The chosen project's past sessions, newest first.
    private(set) var pastSessions: [PastSession] = []
    /// Where the chosen project's repository stands.
    private(set) var status = ProjectStatus(branch: nil, changed: 0)

    /// The model the next message runs on.
    var model: ClaudeModel
    /// How hard Claude thinks.
    var effort: Effort
    /// How Claude Code asks before acting; nil follows your Claude Code settings.
    var mode: PermissionMode?
    /// Whether your next message runs as Claude Code's multi-agent Ultracode.
    var ultracode = false

    private var session: ClaudeSession?
    private var started: (model: ClaudeModel, effort: Effort, mode: PermissionMode?)?
    private var listening: Task<Void, Never>?

    /// A session model for `page`'s chosen project, reading history from `history` and starting Claude Code with `command`.
    init(page: SwiftPageModel, history: ClaudeHistory = ClaudeHistory(), command: [String] = ClaudeSession.claude) {
        self.page = page
        self.history = history
        self.command = command
        transcript = SessionTranscript(folder: page.project.folder)
        model = page.project.defaults.model
        effort = page.project.defaults.effort
    }

    /// Whether Claude is working on a turn.
    var isWorking: Bool { transcript.isWorking }

    /// Claude Code's commands that start with what you've typed after a slash.
    func suggestions(for text: String) -> [SlashCommand] {
        guard text.hasPrefix("/"), !text.contains(" ") else { return [] }
        let typed = text.dropFirst().lowercased()
        return commands.filter { $0.name.lowercased().hasPrefix(typed) }
    }

    /// Reads the chosen project's past sessions and repository status again.
    func refresh() async {
        let folder = page.project.url
        let history = history
        pastSessions = await Task.detached { history.sessions(in: folder) }.value
        status = await ProjectStatus.read(folder)
    }

    /// Sends your message, starting Claude Code in the project's folder first if needed.
    func send(_ text: String) async {
        let text = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return }
        transcript.add(you: text)
        do {
            let session = try await ready()
            try await session.send(ClaudeSession.message(text, ultracode: ultracode))
        } catch {
            transcript.apply(.ended(1))
        }
    }

    /// Answers the request Claude is waiting on.
    func answer(_ request: PermissionRequest, with answer: PermissionAnswer) async {
        transcript.answer(request, with: answer)
        try? await session?.answer(request, with: answer)
    }

    /// Stops the turn Claude is working on.
    func interrupt() async {
        try? await session?.interrupt()
    }

    /// Changes the model; a running session switches at once.
    func setModel(_ model: ClaudeModel) async {
        self.model = model
        if let session { try? await session.setModel(model); started?.model = model }
    }

    /// Changes how Claude Code asks; a running session switches at once.
    func setMode(_ mode: PermissionMode) async {
        self.mode = mode
        if let session { try? await session.setMode(mode); started?.mode = mode }
    }

    /// Ends the session and starts a fresh one in the same project, with its defaults.
    func newSession() {
        end()
        sessionID = nil
        title = nil
        transcript = SessionTranscript(folder: page.project.folder)
        model = page.project.defaults.model
        effort = page.project.defaults.effort
        ultracode = false
    }

    /// Opens a past session, showing what was said; your next message continues it.
    func resume(_ past: PastSession) {
        end()
        sessionID = past.id
        title = past.title
        transcript = history.transcript(of: past.id, in: page.project.url)
    }

    /// Switches to the project with id `id` and starts fresh there.
    func open(_ id: String) async {
        await page.select(id)
        newSession()
        await refresh()
    }

    /// Ends Claude Code's process; the session can be resumed later.
    func end() {
        listening?.cancel()
        listening = nil
        if let session { Task { await session.stop() } }
        session = nil
        started = nil
    }

    /// The running session, started or restarted so it matches the effort you chose. A restart resumes the same session.
    private func ready() async throws -> ClaudeSession {
        if let session, let started, started.effort == effort {
            if started.model != model { try await session.setModel(model) }
            if started.mode != mode, let mode { try await session.setMode(mode) }
            self.started = (model, effort, mode)
            return session
        }
        end()
        let options = ClaudeSession.Options(folder: page.project.url, model: model, effort: effort, mode: mode, resume: sessionID,
                                            command: command)
        let session = ClaudeSession(options)
        listening = Task { [weak self] in
            for await event in session.events {
                guard let self else { return }
                self.transcript.apply(event)
                switch event {
                case .started(let id, _): self.sessionID = id
                case .finished(let finish): self.sessionID = finish.sessionID ?? self.sessionID
                case .commands(let list): self.commands = list
                default: break
                }
            }
        }
        try await session.start()
        self.session = session
        started = (model, effort, mode)
        return session
    }
}
