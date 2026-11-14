import Foundation
import NestKit
import Testing
@testable import NestApp

/// Swift's sessions work like Claude Code in several terminal tabs: each is its own Claude Code in its own project.
@MainActor
struct SwiftSessionsTests {
    /// A stand-in for Claude Code that writes each message into `sent.txt` in the folder it runs in, then finishes the turn.
    static let standIn = #"""
    while IFS= read -r line; do
      case "$line" in
        *'"type":"user"'*)
          printf '%s\n' "$line" >> sent.txt
          echo '{"type":"system","subtype":"init","session_id":"s-'"$$"'","model":"claude-opus-5-5"}'
          echo '{"type":"assistant","message":{"id":"m1","content":[{"type":"text","text":"Done."}]}}'
          echo '{"type":"result","subtype":"success","is_error":false,"total_cost_usd":0.1,"session_id":"s-'"$$"'"}' ;;
      esac
    done
    """#

    /// A deck of sessions over two git projects, `alpha` and `beta`, both added to Swift.
    func setUp() async throws -> (SwiftSessions, URL, alpha: SwiftProject, beta: SwiftProject) {
        let folder = FileManager.default.temporaryDirectory.appending(path: "SwiftSessionsTests-\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        let script = folder.appending(path: "claude.sh")
        try ("#!/bin/sh\n" + Self.standIn + "\n").write(to: script, atomically: true, encoding: .utf8)
        try FileManager.default.setAttributes([.posixPermissions: 0o755], ofItemAtPath: script.path)
        let store = SwiftSettingsStore(at: folder.appending(path: "settings.json"), nest: folder)
        let page = try SwiftPageModel(store: store, folder: folder, log: nil)
        for name in ["alpha", "beta"] { await page.addProject(at: try repository(in: folder, named: name)) }
        let alpha = try #require(page.projects.first { $0.name.lowercased() == "alpha" })
        let beta = try #require(page.projects.first { $0.name.lowercased() == "beta" })
        let deck = SwiftSessions(page: page, history: ClaudeHistory(home: folder.appending(path: "claude-home")),
                                 command: [script.path])
        return (deck, folder, alpha, beta)
    }

    func repository(in folder: URL, named name: String) throws -> URL {
        let url = folder.appending(path: name)
        try FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
        for arguments in [["init", "-q", "-b", "main"]] {
            let git = Process()
            git.executableURL = URL(fileURLWithPath: "/usr/bin/git")
            git.arguments = arguments
            git.currentDirectoryURL = url
            try git.run()
            git.waitUntilExit()
        }
        return url
    }

    func waitUntil(_ condition: () -> Bool) async {
        for _ in 0..<400 where !condition() { try? await Task.sleep(for: .milliseconds(10)) }
    }

    func sent(in project: SwiftProject) -> String {
        (try? String(contentsOf: project.url.appending(path: "sent.txt"), encoding: .utf8)) ?? ""
    }

    func finish(_ session: SwiftSessionModel, _ text: String) async {
        await session.send(text)
        await waitUntil { !session.isWorking }
    }

    @Test func twoSessionsInTwoProjectsKeepTheirOwnFoldersAndTranscripts() async throws {
        let (deck, folder, alpha, beta) = try await setUp()
        defer { deck.endAll(); try? FileManager.default.removeItem(at: folder) }

        deck.open(alpha.id)
        let first = deck.current
        await finish(first, "build in alpha")
        deck.open(beta.id)

        #expect(deck.current !== first)
        #expect(deck.current.project.id == beta.id)
        #expect(deck.current.transcript.items.isEmpty)
        await finish(deck.current, "build in beta")

        #expect(deck.sessions.count == 2)
        #expect(sent(in: alpha).contains("build in alpha") && !sent(in: alpha).contains("build in beta"))
        #expect(sent(in: beta).contains("build in beta") && !sent(in: beta).contains("build in alpha"))
        #expect(first.transcript.items.first?.text == "build in alpha")
        #expect(first.sessionID != deck.current.sessionID)
    }

    @Test func choosingAProjectReusesAnEmptyTab() async throws {
        let (deck, folder, alpha, beta) = try await setUp()
        defer { deck.endAll(); try? FileManager.default.removeItem(at: folder) }

        deck.open(alpha.id)
        deck.open(beta.id)

        #expect(deck.sessions.count == 1)
        #expect(deck.current.project.id == beta.id)
    }

    @Test func aNewSessionIsAnotherTabInTheSameProjectAndClosingOneEndsOnlyIt() async throws {
        let (deck, folder, alpha, _) = try await setUp()
        defer { deck.endAll(); try? FileManager.default.removeItem(at: folder) }
        deck.open(alpha.id)
        let first = deck.current
        await finish(first, "one")

        deck.newSession()
        let second = deck.current
        #expect(deck.sessions.count == 2)
        #expect(second.project.id == alpha.id)
        await finish(second, "two")

        deck.close(first)
        #expect(deck.sessions.count == 1)
        #expect(deck.current === second)
        await finish(second, "three")
        #expect(sent(in: alpha).contains("three"))

        deck.close(second)
        #expect(deck.sessions.count == 1)
        #expect(deck.current.transcript.items.isEmpty)
    }

    @Test func showingATabLeavesTheOthersRunning() async throws {
        let (deck, folder, alpha, beta) = try await setUp()
        defer { deck.endAll(); try? FileManager.default.removeItem(at: folder) }
        deck.open(alpha.id)
        let first = deck.current
        await finish(first, "one")
        deck.open(beta.id)

        deck.show(first)

        #expect(deck.current === first)
        #expect(deck.current.transcript.items.first?.text == "one")
        await waitUntil { deck.page.selected == alpha.id }
        #expect(deck.page.selected == alpha.id)
    }

    @Test func clearStartsTheTabFresh() async throws {
        let (deck, folder, alpha, _) = try await setUp()
        defer { deck.endAll(); try? FileManager.default.removeItem(at: folder) }
        deck.open(alpha.id)
        await finish(deck.current, "hello")
        #expect(deck.current.sessionID != nil)

        await deck.current.send("/clear")

        #expect(deck.current.transcript.items.isEmpty)
        #expect(deck.current.sessionID == nil)
        #expect(!sent(in: alpha).contains("/clear"))
    }

    @Test func aPastSessionOpensInItsOwnTab() async throws {
        let (deck, folder, alpha, _) = try await setUp()
        defer { deck.endAll(); try? FileManager.default.removeItem(at: folder) }
        deck.open(alpha.id)
        await finish(deck.current, "now")

        deck.resume(PastSession(id: "old-1", title: "Fix the budget", lastActive: .now, messages: 1))

        #expect(deck.sessions.count == 2)
        #expect(deck.current.sessionID == "old-1")
        #expect(deck.current.tabTitle == "Fix the budget")
    }
}
