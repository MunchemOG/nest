import Foundation
import Testing
@testable import NestKit

struct UsageLogTests {
    static let resetsWeekly = Date(timeIntervalSince1970: 1_794_693_600)

    /// A session's stream-json output: its rate-limit event, then its result with the cost Claude reports.
    static func stream(cost: Double, weekly: Double, fiveHour: Double = 0.5, fiveHourResets: Double = 1_794_625_200,
                       result: String = "Result: done") -> String {
        """
        {"type":"system","subtype":"init","session_id":"s"}
        {"type":"rate_limit_event","rate_limit_info":{"status":"allowed","unifiedWindows":{"five_hour":{"utilization":\(fiveHour),"resetsAt":\(fiveHourResets),"status":"allowed"},"seven_day":{"utilization":\(weekly),"resetsAt":1794693600,"status":"allowed"}}}}
        {"type":"result","subtype":"success","total_cost_usd":\(cost),"result":\(String(data: try! JSONEncoder().encode(result), encoding: .utf8)!),"usage":{"input_tokens":3,"output_tokens":200,"cache_read_input_tokens":5000,"cache_creation_input_tokens":700},"modelUsage":{"claude-sonnet-5-5":{"costUSD":\(cost)}}}
        """
    }

    static func at(_ hour: Int, _ minute: Int) -> Date {
        Date(timeIntervalSince1970: 1_794_600_000 + Double(hour * 3600 + minute * 60))
    }

    @Test func readsCostTokensAndLimitsFromASession() throws {
        let usage = try #require(SessionUsage(output: Self.stream(cost: 2.18, weekly: 0.72, fiveHour: 0.66, result: "Did it.\nResult: done")))
        #expect(usage.costUSD == 2.18)
        #expect(usage.outputTokens == 200)
        #expect(usage.inputTokens == 3 + 5000 + 700)
        #expect(usage.models == ["claude-sonnet-5-5"])
        #expect(usage.limits?.weekly == 0.72)
        #expect(usage.limits?.fiveHour == 0.66)
        #expect(usage.limits?.weeklyResets == Self.resetsWeekly)
        #expect(usage.text == "Did it.\nResult: done")
        #expect(SessionUsage(output: "Result: done\nDid: plain text") == nil)
    }

    @Test func afterANightsRunTheLogsTotalMatchesWhatClaudeReports() async throws {
        let folder = FileManager.default.temporaryDirectory.appending(path: "UsageLogTests-\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: folder) }
        let log = try UsageLog(at: folder.appending(path: "usage.sqlite"))
        // Two pairs of back-to-back tasks, with a morning gap in which you chatted.
        let night: [(String, Double, Double, Date, Date)] = [
            ("T9-01", 2.0, 0.40, Self.at(22, 0), Self.at(22, 29)),
            ("T9-02", 1.0, 0.42, Self.at(22, 30), Self.at(22, 50)),
            ("T9-03", 1.0, 0.47, Self.at(31, 0), Self.at(31, 19)),
            ("T9-04", 3.0, 0.48, Self.at(31, 20), Self.at(31, 50)),
        ]
        for (task, cost, weekly, started, ended) in night {
            let usage = try #require(SessionUsage(output: Self.stream(cost: cost, weekly: weekly)))
            try await log.record(task: task, usage: usage, started: started, ended: ended)
        }

        let report = try await log.report(from: Self.at(21, 0), to: Self.at(32, 0))

        #expect(report.tasks.map(\.task) == ["T9-01", "T9-02", "T9-03", "T9-04"])
        #expect(report.costUSD == 7.0, "the log's cost is not what Claude reported")
        #expect(abs(report.weeklyPerDollar - 0.01) < 1e-9)
        #expect(report.tasks.map(\.weekly).map { ($0 * 1000).rounded() / 1000 } == [0.02, 0.01, 0.01, 0.03])
        #expect(abs(report.chatsWeekly - 0.04) < 1e-9, "your chats in the morning gap were not counted")
        // Claude reports weekly use going from 40% to 48% between the first and last sessions.
        #expect(abs(report.reportedWeekly - 0.08) < 1e-9)
        let logged = report.tasks.dropLast().map(\.weekly).reduce(0, +) + report.chatsWeekly
        #expect(abs(logged - report.reportedWeekly) <= 0.03 * report.reportedWeekly)
    }

    @Test func aFiveHourResetStartsItsCountAgain() async throws {
        let folder = FileManager.default.temporaryDirectory.appending(path: "UsageLogTests-\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: folder) }
        let log = try UsageLog(at: folder.appending(path: "usage.sqlite"))
        try await log.record(task: "T9-01", usage: try #require(SessionUsage(output: Self.stream(cost: 1, weekly: 0.1, fiveHour: 0.9))),
                             started: Self.at(1, 0), ended: Self.at(1, 30))
        try await log.record(task: "T9-02", usage: try #require(SessionUsage(output: Self.stream(cost: 1, weekly: 0.11, fiveHour: 0.05,
                                                                                                    fiveHourResets: 1_794_643_200))),
                             started: Self.at(6, 0), ended: Self.at(6, 30))
        let report = try await log.report(from: Self.at(0, 0), to: Self.at(7, 0))
        #expect(abs(report.reportedFiveHour - 0.05) < 1e-9, "a reset window counts only what was used since the reset")
    }

    @Test func entriesSurviveReopeningTheLog() async throws {
        let folder = FileManager.default.temporaryDirectory.appending(path: "UsageLogTests-\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: folder) }
        let url = folder.appending(path: "usage.sqlite")
        try await UsageLog(at: url).record(task: "T9-01", usage: try #require(SessionUsage(output: Self.stream(cost: 1.25, weekly: 0.3))),
                                           started: Self.at(1, 0), ended: Self.at(1, 30))
        let entries = try await UsageLog(at: url).entries()
        #expect(entries.map(\.task) == ["T9-01"])
        #expect(entries.first?.costUSD == 1.25)
        #expect(entries.first?.limits?.weekly == 0.3)
        #expect(entries.first?.started == Self.at(1, 0))
    }

    @Test func theRunnerReadsTheSummaryBlockFromStreamOutputAndKeepsItsUsage() async throws {
        let repo = try await TempRepo()
        defer { repo.remove() }
        let summary = "Result: done\nDid: Added the greeting file.\nTests: 1/1, 1 new\nFiles: greeting.txt\nNoticed: nothing\nNext: none"
        let session = """
        echo hello > greeting.txt
        git add greeting.txt
        git commit -q -m "T9-01: Add the greeting"
        cat <<'JSON'
        \(Self.stream(cost: 0.42, weekly: 0.5, result: summary))
        JSON
        """
        let runner = ManualRunner(repository: repo.url, session: try repo.script("session", session), tests: ["true"])
        let outcome = try await runner.run(ManualRunnerTests.task)
        #expect(outcome.isDone, "\(outcome.held ?? "")")
        #expect(outcome.summary?.did == "Added the greeting file.")
        #expect(outcome.usage?.costUSD == 0.42)
    }

    @Test func theQueueRunnerLogsEachSessionsCost() async throws {
        let repo = try await TempRepo()
        defer { repo.remove() }
        let session = """
        id=$(printf '%s' "$1" | grep -o 'Do task [A-Z0-9-]*' | cut -d' ' -f3)
        echo "$id" > "$id.txt"
        git add -A
        git commit -q -m "$id: Add $id.txt"
        cat <<'JSON'
        \(Self.stream(cost: 0.75, weekly: 0.2, result: "Result: done\nDid: It."))
        JSON
        """
        let queue = try TaskQueue(at: repo.url.appending(path: ".git/queue.sqlite"))
        let log = try UsageLog(at: repo.url.appending(path: ".git/usage.sqlite"))
        try await queue.add(QueuedTask(id: "T9-01", goal: "One", doneMeans: "One"))
        try await queue.add(QueuedTask(id: "T9-02", goal: "Two", doneMeans: "Two"))
        let runner = QueueRunner(queue: queue, runner: ManualRunner(repository: repo.url, session: try repo.script("s", session),
                                                                    tests: ["true"]), usageLog: log)
        _ = try await runner.runUntilEmpty()
        let entries = try await log.entries()
        #expect(entries.map(\.task) == ["T9-01", "T9-02"])
        #expect(entries.map(\.costUSD) == [0.75, 0.75])
        #expect(entries.allSatisfy { $0.ended >= $0.started })
    }
}
