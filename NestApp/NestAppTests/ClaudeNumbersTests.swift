import Foundation
import NestKit
import Testing
@testable import NestApp

/// Swift shows Claude Code's own numbers: each limit with its reset, your plan, and how full the context is.
@MainActor
struct ClaudeNumbersTests {
    /// A stand-in for Claude Code that answers `initialize`, `get_usage` and `get_context_usage` as Claude Code 2.1 does,
    /// logs each request it is asked, and finishes any message at once.
    static let standIn = #"""
    while IFS= read -r line; do
      case "$line" in
        *'"subtype":"initialize"'*)
          echo '{"type":"control_response","response":{"subtype":"success","request_id":"x","response":{"commands":[],"account":{"email":"you@nest.invalid","subscriptionType":"Claude Pro"}}}}' ;;
        *'"subtype":"get_usage"'*)
          echo get_usage >> asked.txt
          echo '{"type":"control_response","response":{"subtype":"success","request_id":"x","response":{"session":{"total_cost_usd":0.5,"total_lines_added":12,"total_lines_removed":3},"subscription_type":"pro","rate_limits":{"limits":[{"kind":"session","percent":2,"resets_at":"2026-11-15T02:39:59.5+00:00","severity":"normal"},{"kind":"weekly_all","percent":90,"resets_at":"2026-11-14T21:59:59.5+00:00","severity":"critical"},{"kind":"weekly_scoped","percent":42,"resets_at":"2026-11-14T21:59:59.5+00:00","severity":"normal","scope":{"model":{"display_name":"Fable"}}}]}}}}' ;;
        *'"subtype":"get_context_usage"'*)
          echo get_context_usage >> asked.txt
          echo '{"type":"control_response","response":{"subtype":"success","request_id":"x","response":{"totalTokens":20000,"maxTokens":1000000,"autoCompactThreshold":967000,"isAutoCompactEnabled":true}}}' ;;
        *'"type":"user"'*)
          echo '{"type":"system","subtype":"init","session_id":"s-1","model":"claude-opus-5-5"}'
          echo '{"type":"assistant","message":{"id":"m1","content":[{"type":"text","text":"Done."}]}}'
          echo '{"type":"result","subtype":"success","is_error":false,"total_cost_usd":0.5,"session_id":"s-1"}' ;;
      esac
    done
    """#

    func setUp() throws -> (SwiftSessionModel, URL) {
        let folder = FileManager.default.temporaryDirectory.appending(path: "ClaudeNumbersTests-\(UUID().uuidString)")
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

    static func date(_ text: String) -> Date { try! Date(text, strategy: .iso8601) }

    @Test func swiftShowsEachLimitWithItsResetAndYourPlanWithoutAUsageLog() async throws {
        let (session, folder) = try setUp()
        defer { session.end(); try? FileManager.default.removeItem(at: folder) }

        await session.checkUsage()

        let page = session.page
        #expect(page.claude?.limits.map(\.title) == ["Session", "Week", "Fable's week"])
        #expect(page.claude?.limits.map(\.used) == [0.02, 0.9, 0.42])
        #expect(page.claude?.limits.first?.resets == Self.date("2026-11-15T02:39:59Z"))
        #expect(page.account?.plan == "Claude Pro")
        #expect(page.reported?.weekly == 0.9)
        #expect(page.reported?.fiveHour == 0.02)
        #expect(page.usage == "90% of the week used · 2% of the five hours")
    }

    @Test func aResetSaysItsTimeAndItsDayWhenNotToday() {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "America/Chicago")!
        let now = Self.date("2026-11-14T18:00:00Z")
        #expect(SwiftPageModel.resets(Self.date("2026-11-14T21:59:59Z"), now: now, calendar: calendar) == "resets 15:59")
        #expect(SwiftPageModel.resets(Self.date("2026-11-15T02:39:59Z"), now: now, calendar: calendar) == "resets 20:39")
        #expect(SwiftPageModel.resets(Self.date("2026-11-16T02:39:59Z"), now: now, calendar: calendar) == "resets Sun 20:39")
    }

    @Test func afterEachTurnSwiftAsksAgainAndShowsHowFullTheContextIs() async throws {
        let (session, folder) = try setUp()
        defer { session.end(); try? FileManager.default.removeItem(at: folder) }

        await session.send("tidy up")
        await waitUntil { session.context != nil && session.page.claude != nil }

        #expect(session.context?.used == 0.02)
        #expect(session.contextLine == "Context 2% full")
        #expect(session.page.claude?.linesAdded == 12)
        let asked = try String(contentsOf: folder.appending(path: "asked.txt"), encoding: .utf8)
        #expect(asked.contains("get_usage"))
        #expect(asked.contains("get_context_usage"))
    }
}
