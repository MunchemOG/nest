import Foundation
import NestKit
import Testing
@testable import NestApp

@MainActor
struct SwiftSessionTests {
    /// A stand-in for Claude Code: it records its arguments and each message, streams a reply, and asks to run a command.
    static let standIn = #"""
    printf '%s\n' "$@" > args.txt
    echo '{"type":"system","subtype":"init","session_id":"s-1","model":"claude-opus-5-5"}'
    while IFS= read -r line; do
      case "$line" in
        *'"subtype":"initialize"'*)
          echo '{"type":"control_response","response":{"subtype":"success","request_id":"x","response":{"commands":[{"name":"compact","description":"Compact"},{"name":"cost","description":"Cost"}]}}}' ;;
        *'"type":"user"'*)
          printf '%s\n' "$line" >> sent.txt
          echo '{"type":"assistant","message":{"id":"m1","content":[{"type":"text","text":"On it."}]}}'
          echo '{"type":"assistant","message":{"id":"m2","content":[{"type":"tool_use","id":"t1","name":"Bash","input":{"command":"swift test"}}]}}'
          echo '{"type":"control_request","request_id":"p1","request":{"subtype":"can_use_tool","tool_name":"Bash","input":{"command":"swift test"},"description":"Run tests","permission_suggestions":[]}}' ;;
        *'"type":"control_response"'*)
          printf '%s\n' "$line" > answer.txt
          echo '{"type":"user","message":{"role":"user","content":[{"type":"tool_result","tool_use_id":"t1","content":"9/9 passed"}]}}'
          echo '{"type":"result","subtype":"success","is_error":false,"total_cost_usd":0.12,"session_id":"s-1"}' ;;
      esac
    done
    """#

    func setUp() throws -> (SwiftSessionModel, URL) {
        let folder = FileManager.default.temporaryDirectory.appending(path: "SwiftSessionTests-\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        let script = folder.appending(path: "claude.sh")
        try ("#!/bin/sh\n" + Self.standIn + "\n").write(to: script, atomically: true, encoding: .utf8)
        try FileManager.default.setAttributes([.posixPermissions: 0o755], ofItemAtPath: script.path)
        let store = SwiftSettingsStore(at: folder.appending(path: "settings.json"), nest: folder)
        let page = try SwiftPageModel(store: store, folder: folder, log: nil)
        let history = ClaudeHistory(home: folder.appending(path: "claude-home"))
        return (SwiftSessionModel(page: page, history: history, command: [script.path]), folder)
    }

    func waitUntil(_ condition: () -> Bool) async {
        for _ in 0..<400 where !condition() { try? await Task.sleep(for: .milliseconds(10)) }
    }

    @Test func aMessageReachesClaudeCodeWithYourModelEffortAndUltracode() async throws {
        let (session, folder) = try setUp()
        defer { session.end(); try? FileManager.default.removeItem(at: folder) }
        session.model = .opus
        session.effort = .max
        session.ultracode = true

        await session.send("audit the budget")
        await waitUntil { session.transcript.waiting != nil }

        let args = try String(contentsOf: folder.appending(path: "args.txt"), encoding: .utf8).split(separator: "\n").map(String.init)
        #expect(args[args.firstIndex(of: "--model")! + 1] == "opus")
        #expect(args[args.firstIndex(of: "--effort")! + 1] == "max")
        let sent = try String(contentsOf: folder.appending(path: "sent.txt"), encoding: .utf8)
        #expect(sent.contains("ultracode audit the budget"))
        #expect(session.transcript.items.first?.text == "audit the budget")
        #expect(session.commands.map(\.name) == ["compact", "cost"])
        #expect(session.isWorking)
    }

    @Test func allowOnACardAnswersTheRequest() async throws {
        let (session, folder) = try setUp()
        defer { session.end(); try? FileManager.default.removeItem(at: folder) }
        await session.send("run the tests")
        await waitUntil { session.transcript.waiting != nil }
        let request = try #require(session.transcript.waiting)

        await session.answer(request, with: .allow)
        await waitUntil { !session.isWorking }

        let answer = try String(contentsOf: folder.appending(path: "answer.txt"), encoding: .utf8)
        #expect(answer.contains(#""behavior":"allow""#))
        #expect(session.transcript.items.compactMap(\.tool).first?.result == "9/9 passed")
        #expect(session.transcript.items.last?.kind == .finished)
        #expect(session.sessionID == "s-1")
        #expect(session.transcript.costUSD == 0.12)
    }

    @Test func slashSuggestionsComeFromClaudeCode() async throws {
        let (session, folder) = try setUp()
        defer { session.end(); try? FileManager.default.removeItem(at: folder) }
        await session.send("hi")
        await waitUntil { !session.commands.isEmpty }
        #expect(session.suggestions(for: "/co").map(\.name) == ["compact", "cost"])
        #expect(session.suggestions(for: "/cos").map(\.name) == ["cost"])
        #expect(session.suggestions(for: "hello").isEmpty)
    }

    @Test func aNewSessionStartsCleanAndTheProjectsDefaultsComeBack() async throws {
        let (session, folder) = try setUp()
        defer { session.end(); try? FileManager.default.removeItem(at: folder) }
        await session.send("hi")
        await waitUntil { session.sessionID != nil }

        session.newSession()

        #expect(session.transcript.items.isEmpty)
        #expect(session.sessionID == nil)
        #expect(session.model == session.page.project.defaults.model)
    }
}
