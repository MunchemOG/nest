import Foundation
import NestKit
import Observation

/// Swift's open sessions, like Claude Code in several terminal tabs: each is its own Claude Code in its own project,
/// they keep running while you look at another, and one is in front.
@MainActor
@Observable
final class SwiftSessions {
    /// Your projects and limits.
    let page: SwiftPageModel
    /// Claude Code's own record of past sessions.
    let history: ClaudeHistory
    private let command: [String]

    /// The open sessions, in the order you opened them.
    private(set) var sessions: [SwiftSessionModel]
    /// The session in front.
    private(set) var current: SwiftSessionModel

    /// One fresh session in `page`'s chosen project, reading history from `history` and starting Claude Code with `command`.
    init(page: SwiftPageModel, history: ClaudeHistory = ClaudeHistory(), command: [String] = ClaudeSession.claude) {
        self.page = page
        self.history = history
        self.command = command
        let first = SwiftSessionModel(page: page, history: history, command: command)
        sessions = [first]
        current = first
    }

    /// Sessions holding just `session`, which is in front.
    init(holding session: SwiftSessionModel) {
        page = session.page
        history = session.history
        command = session.command
        sessions = [session]
        current = session
    }

    /// Opens a fresh session in the project with id `id` at once, reusing the front tab if nothing has happened in it.
    func open(_ id: String) {
        guard page.projects.contains(where: { $0.id == id }) else { return }
        if current.isEmpty {
            current.move(to: id)
        } else {
            add(SwiftSessionModel(page: page, project: id, history: history, command: command))
        }
        follow()
    }

    /// Opens another fresh session in the front session's project.
    func newSession() {
        add(SwiftSessionModel(page: page, project: current.projectID, history: history, command: command))
    }

    /// Opens a past session of the front session's project in its own tab, or in the front tab if it is empty.
    func resume(_ past: PastSession) {
        if !current.isEmpty { newSession() }
        current.resume(past)
    }

    /// Puts `session` in front; the others keep running.
    func show(_ session: SwiftSessionModel) {
        guard sessions.contains(where: { $0 === session }) else { return }
        current = session
        follow()
    }

    /// Closes `session`'s tab and ends its Claude Code; the last tab closed leaves a fresh one in its project.
    func close(_ session: SwiftSessionModel) {
        guard let index = sessions.firstIndex(where: { $0 === session }) else { return }
        session.end()
        sessions.remove(at: index)
        if sessions.isEmpty {
            sessions = [SwiftSessionModel(page: page, project: session.projectID, history: history, command: command)]
        }
        if current === session {
            current = sessions[min(index, sessions.count - 1)]
            follow()
        }
    }

    /// Ends every session's Claude Code.
    func endAll() {
        sessions.forEach { $0.end() }
    }

    private func add(_ session: SwiftSessionModel) {
        sessions.append(session)
        current = session
    }

    /// Makes the page show the front session's project, and reads that project's sessions and status.
    private func follow() {
        let session = current
        Task {
            if page.selected != session.projectID { await page.select(session.projectID) }
            await session.refresh()
        }
    }
}
