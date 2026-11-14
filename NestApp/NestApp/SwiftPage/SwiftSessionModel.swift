import Foundation
import NestKit
import Observation

/// One Claude Code session in one project: a tab in Swift, shared by the close-up and the small Swift.
/// It only drives Claude Code; everything it shows is what Claude Code said.
@MainActor
@Observable
final class SwiftSessionModel: Identifiable {
    /// Your projects and limits.
    let page: SwiftPageModel
    /// Claude Code's own record of past sessions.
    let history: ClaudeHistory
    /// The command that starts Claude Code.
    let command: [String]
    /// The id of the project this session runs in.
    private(set) var projectID: String

    /// What you see of the session.
    private(set) var transcript: SessionTranscript
    /// The session's id once Claude Code has given it, for resuming.
    private(set) var sessionID: String?
    /// The title of the session you resumed, or nil for a new one.
    private(set) var title: String?
    /// Claude Code's slash commands.
    private(set) var commands: [SlashCommand] = []
    /// This project's past sessions, newest first.
    private(set) var pastSessions: [PastSession] = []
    /// Where this project's repository stands.
    private(set) var status = ProjectStatus(branch: nil, changed: 0)
    /// How full the live session's context is, once Claude Code has said.
    private(set) var context: ContextUsage?

    /// The model the next message runs on.
    var model: ClaudeModel
    /// How hard Claude thinks.
    var effort: Effort
    /// How Claude Code asks before acting; nil follows your Claude Code settings.
    var mode: PermissionMode?
    /// Whether your next message runs as Claude Code's multi-agent Ultracode.
    var ultracode = false
    /// What you've typed and not sent yet, kept while you look at another tab.
    var draft = ""

    private var session: ClaudeSession?
    private var started: (model: ClaudeModel, effort: Effort, mode: PermissionMode?)?
    private var listening: Task<Void, Never>?

    /// A session in the project with id `project` (`page`'s chosen one when nil), reading history from `history`
    /// and starting Claude Code with `command`.
    init(page: SwiftPageModel, project id: String? = nil, history: ClaudeHistory = ClaudeHistory(),
         command: [String] = ClaudeSession.claude) {
        self.page = page
        self.history = history
        self.command = command
        let project = page.projects.first { $0.id == id } ?? page.project
        projectID = project.id
        transcript = SessionTranscript(folder: project.folder)
        model = project.defaults.model
        effort = project.defaults.effort
    }

    /// The project this session runs in.
    var project: SwiftProject { page.projects.first { $0.id == projectID } ?? page.project }

    /// Whether nothing has happened in this session yet, so choosing a project can reuse it.
    var isEmpty: Bool { transcript.items.isEmpty && sessionID == nil && session == nil }

    /// Whether Claude is waiting on your answer.
    var isWaiting: Bool { transcript.waiting != nil }

    /// The tab's name: the session's title, or what you first said, or "New session".
    var tabTitle: String {
        title ?? transcript.items.first { $0.kind == .you }?.text.split(separator: "\n").first.map(String.init) ?? "New session"
    }

    /// Whether Claude is working on a turn.
    var isWorking: Bool { transcript.isWorking }

    /// Claude Code's commands that start with what you've typed after a slash.
    func suggestions(for text: String) -> [SlashCommand] {
        guard text.hasPrefix("/"), !text.contains(" ") else { return [] }
        let typed = text.dropFirst().lowercased()
        return commands.filter { $0.name.lowercased().hasPrefix(typed) }
    }

    /// How full the context is, in a few words, or nil before Claude Code has said.
    var contextLine: String? {
        context.map { "Context \(SwiftPageModel.percent($0.used)) full" }
    }

    /// Asks Claude Code for your usage: the live session if there is one, or else Claude Code started just to ask.
    /// Reading it costs no usage.
    func checkUsage() async {
        if let session {
            try? await session.checkUsage()
            return
        }
        let options = ClaudeSession.Options(folder: project.url, model: model, effort: effort, command: command)
        let read = await ClaudeSession.readUsage(options)
        if let usage = read.usage { page.heard(usage) }
        if let account = read.account { page.heard(account) }
    }

    /// Reads this project's past sessions and repository status again.
    func refresh() async {
        let folder = project.url
        let history = history
        pastSessions = await Task.detached { history.sessions(in: folder) }.value
        status = await ProjectStatus.read(folder)
    }

    /// Sends your message, starting Claude Code in the project's folder first if needed.
    func send(_ text: String) async {
        let text = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return }
        if text == "/clear" {
            newSession()
            return
        }
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
        transcript = SessionTranscript(folder: project.folder)
        context = nil
        model = project.defaults.model
        effort = project.defaults.effort
        ultracode = false
    }

    /// Opens a past session, showing what was said; your next message continues it.
    func resume(_ past: PastSession) {
        end()
        sessionID = past.id
        title = past.title
        context = nil
        transcript = history.transcript(of: past.id, in: project.url)
    }

    /// Moves this session to the project with id `id` and starts fresh there at once; the page follows.
    func open(_ id: String) async {
        move(to: id)
        await page.select(id)
        await refresh()
    }

    /// Moves this session to the project with id `id`, fresh, without waiting for anything.
    func move(to id: String) {
        guard page.projects.contains(where: { $0.id == id }) else { return }
        projectID = id
        newSession()
        pastSessions = []
        status = ProjectStatus(branch: nil, changed: 0)
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
        let options = ClaudeSession.Options(folder: project.url, model: model, effort: effort, mode: mode, resume: sessionID,
                                            command: command)
        let session = ClaudeSession(options)
        listening = Task { [weak self] in
            for await event in session.events {
                guard let self else { return }
                self.transcript.apply(event)
                switch event {
                case .started(let id, _): self.sessionID = id
                case .finished(let finish):
                    self.sessionID = finish.sessionID ?? self.sessionID
                    try? await session.checkUsage()
                case .commands(let list): self.commands = list
                case .usage(let usage): self.page.heard(usage)
                case .limits(let snapshot): self.page.heard(snapshot)
                case .context(let context): self.context = context
                case .account(let account): self.page.heard(account)
                default: break
                }
            }
        }
        try await session.start()
        self.session = session
        started = (model, effort, mode)
        try await session.checkUsage()
        return session
    }
}
