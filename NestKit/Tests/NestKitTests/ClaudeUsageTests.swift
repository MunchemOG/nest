import Foundation
import Testing
@testable import NestKit

struct ClaudeUsageTests {
    /// Claude Code's answer to `get_usage`, cut to what Swift reads, as Claude Code 2.1 writes it.
    static let usageLine = #"""
    {"type":"control_response","response":{"subtype":"success","request_id":"swift-2","response":{"session":{"total_cost_usd":1.25,"total_lines_added":40,"total_lines_removed":7},"subscription_type":"pro","rate_limits_available":true,"rate_limits":{"five_hour":{"utilization":2,"resets_at":"2026-11-15T02:39:59.518312+00:00"},"seven_day":{"utilization":90,"resets_at":"2026-11-14T21:59:59.518336+00:00"},"limits":[{"kind":"session","group":"session","percent":2,"resets_at":"2026-11-15T02:39:59.518312+00:00","severity":"normal","scope":null},{"kind":"weekly_all","group":"weekly","percent":90,"resets_at":"2026-11-14T21:59:59.518336+00:00","severity":"critical","scope":null},{"kind":"weekly_scoped","group":"weekly","percent":42,"resets_at":"2026-11-14T21:59:59.518613+00:00","severity":"normal","scope":{"model":{"display_name":"Fable","id":null},"surface":null}}]}}}}
    """#

    static let contextLine = #"""
    {"type":"control_response","response":{"subtype":"success","request_id":"swift-3","response":{"totalTokens":20193,"maxTokens":1000000,"percentage":2,"model":"claude-opus-5-5","autoCompactThreshold":967000,"isAutoCompactEnabled":true}}}
    """#

    static let initializeLine = #"""
    {"type":"control_response","response":{"subtype":"success","request_id":"swift-1","response":{"commands":[{"name":"compact","description":"Compact"}],"account":{"email":"you@nest.invalid","subscriptionType":"Claude Pro","apiProvider":"firstParty"}}}}
    """#

    static func date(_ text: String) -> Date {
        try! Date(text, strategy: .iso8601)
    }

    @Test func claudeCodesUsageReportGivesEachLimitWithItsReset() throws {
        guard case .usage(let usage)? = ClaudeEvent(line: Self.usageLine) else { Issue.record("not read as usage"); return }
        #expect(usage.plan == "Pro")
        #expect(usage.limits.map(\.title) == ["Session", "Week", "Fable's week"])
        #expect(usage.limits.map(\.used) == [0.02, 0.9, 0.42])
        #expect(usage.limits.map(\.isCritical) == [false, true, false])
        #expect(usage.limits[0].resets == Self.date("2026-11-15T02:39:59Z"))
        #expect(usage.limits[1].resets == Self.date("2026-11-14T21:59:59Z"))
        #expect(usage.costUSD == 1.25)
        #expect(usage.linesAdded == 40)
        #expect(usage.linesRemoved == 7)
        let snapshot = try #require(usage.snapshot)
        #expect(snapshot.fiveHour == 0.02)
        #expect(snapshot.weekly == 0.9)
        #expect(snapshot.weeklyResets == Self.date("2026-11-14T21:59:59Z"))
    }

    @Test func contextShowsHowFullItIsAndWhenItCompacts() {
        guard case .context(let context)? = ClaudeEvent(line: Self.contextLine) else { Issue.record("not read as context"); return }
        #expect(context == ContextUsage(usedTokens: 20193, maxTokens: 1_000_000, compactsAt: 967_000))
        #expect(context.used == 0.020193)
    }

    @Test func initializeGivesTheCommandsAndWhoIsSignedIn() {
        let events = ClaudeEvent.all(in: Self.initializeLine)
        #expect(events == [.commands([SlashCommand(name: "compact", description: "Compact")]),
                           .account(ClaudeAccount(email: "you@nest.invalid", plan: "Claude Pro"))])
        #expect(ClaudeEvent(line: Self.initializeLine) == .commands([SlashCommand(name: "compact", description: "Compact")]))
    }

    @Test func aSessionAsksClaudeCodeForUsageAndContext() async throws {
        let folder = FileManager.default.temporaryDirectory.appending(path: "ClaudeUsageTests-\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: folder) }
        let script = folder.appending(path: "claude.sh")
        try """
        #!/bin/sh
        while IFS= read -r line; do
          case "$line" in
            *'"subtype":"get_usage"'*) echo '\(Self.usageLine)' ;;
            *'"subtype":"get_context_usage"'*) echo '\(Self.contextLine)' ;;
          esac
        done
        """.write(to: script, atomically: true, encoding: .utf8)
        try FileManager.default.setAttributes([.posixPermissions: 0o755], ofItemAtPath: script.path)
        let session = ClaudeSession(ClaudeSession.Options(folder: folder, model: .sonnet, effort: .high, command: [script.path]))
        var events = session.events.makeAsyncIterator()

        try await session.start()
        try await session.checkUsage()
        var heard: [ClaudeEvent] = []
        while heard.count < 2, let event = await events.next() { heard.append(event) }
        await session.stop()

        #expect(heard.contains { if case .usage = $0 { true } else { false } })
        #expect(heard.contains { if case .context = $0 { true } else { false } })
    }

    @Test func usageCanBeReadWithoutALiveSession() async throws {
        let folder = FileManager.default.temporaryDirectory.appending(path: "ClaudeUsageTests-\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: folder) }
        let script = folder.appending(path: "claude.sh")
        try """
        #!/bin/sh
        while IFS= read -r line; do
          case "$line" in
            *'"subtype":"initialize"'*) echo '\(Self.initializeLine)' ;;
            *'"subtype":"get_usage"'*) echo '\(Self.usageLine)' ;;
          esac
        done
        """.write(to: script, atomically: true, encoding: .utf8)
        try FileManager.default.setAttributes([.posixPermissions: 0o755], ofItemAtPath: script.path)

        let read = await ClaudeSession.readUsage(ClaudeSession.Options(folder: folder, model: .sonnet, effort: .high,
                                                                       command: [script.path]))

        #expect(read.usage?.limits.count == 3)
        #expect(read.account?.plan == "Claude Pro")
    }
}
