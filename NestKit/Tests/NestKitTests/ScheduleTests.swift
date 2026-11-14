import Foundation
import Testing
@testable import NestKit

struct ScheduleTests {
    static let calendar = ClaudeHistoryTests.calendar

    /// 2026-11-16 is a Monday.
    static func monday(_ day: Int = 0, _ hour: Int, _ minute: Int = 0) -> Date {
        calendar.date(from: DateComponents(year: 2026, month: 11, day: 16 + day, hour: hour, minute: minute))!
    }

    /// You work weekdays 09:00 to 17:59, on each of the last three weeks.
    static var pattern: WorkPattern {
        var times: [Date] = []
        for week in 1...3 {
            for day in 0..<5 {
                for hour in 9..<18 { times.append(monday(day - 7 * week, hour, 15)) }
            }
        }
        return WorkPattern(messages: times, now: monday(0, 8), calendar: calendar)
    }

    @Test func yourHoursAreLearnedFromWhenYouTalkToClaude() {
        let pattern = Self.pattern
        #expect(pattern.isYours(Self.monday(0, 10)))
        #expect(!pattern.isYours(Self.monday(0, 20)))
        #expect(!pattern.isYours(Self.monday(5, 10)))
        #expect(pattern.nextGap(after: Self.monday(0, 10)) == Self.monday(0, 18))
        #expect(pattern.nextGap(after: Self.monday(0, 20, 30)) == Self.monday(0, 20, 30))
    }

    @Test func anHourYouWorkedOnlyOnceStaysAGap() {
        let once = WorkPattern(messages: [Self.monday(-7, 3)], now: Self.monday(0, 1), calendar: Self.calendar)
        #expect(!once.isYours(Self.monday(0, 3)))
    }

    @Test func jobsComeDueByTheirTiming() {
        let pattern = Self.pattern
        func job(_ timing: JobTiming, lastRun: Date? = nil) -> SwiftJob {
            SwiftJob(id: "j1", project: "nest", prompt: "Tidy", settings: .everyday, ultracode: false, mode: .acceptEdits,
                     timing: timing, created: Self.monday(0, 8), lastRun: lastRun)
        }
        #expect(!job(.nextGap).isDue(at: Self.monday(0, 10), pattern: pattern, calendar: Self.calendar))
        #expect(job(.nextGap).isDue(at: Self.monday(0, 19), pattern: pattern, calendar: Self.calendar))
        #expect(!job(.nextGap, lastRun: Self.monday(0, 19)).isDue(at: Self.monday(0, 23), pattern: pattern, calendar: Self.calendar))
        #expect(!job(.tonight).isDue(at: Self.monday(0, 19), pattern: pattern, calendar: Self.calendar))
        #expect(job(.tonight).isDue(at: Self.monday(0, 22), pattern: pattern, calendar: Self.calendar))
        #expect(!job(.at(Self.monday(1, 3))).isDue(at: Self.monday(1, 2), pattern: pattern, calendar: Self.calendar))
        #expect(job(.at(Self.monday(1, 3))).isDue(at: Self.monday(1, 3, 5), pattern: pattern, calendar: Self.calendar))
        #expect(job(.nightly(hour: 1)).isDue(at: Self.monday(1, 1, 30), pattern: pattern, calendar: Self.calendar))
        #expect(!job(.nightly(hour: 1), lastRun: Self.monday(1, 1, 10)).isDue(at: Self.monday(1, 2), pattern: pattern, calendar: Self.calendar))
        #expect(job(.nightly(hour: 1), lastRun: Self.monday(0, 1, 10)).isDue(at: Self.monday(1, 2), pattern: pattern, calendar: Self.calendar))
        #expect(job(.weekly(weekday: 3, hour: 2)).isDue(at: Self.monday(1, 2), pattern: pattern, calendar: Self.calendar))
        #expect(!job(.weekly(weekday: 4, hour: 2)).isDue(at: Self.monday(1, 2), pattern: pattern, calendar: Self.calendar))
    }

    @Test func jobsSurviveBeingSaved() throws {
        let folder = FileManager.default.temporaryDirectory.appending(path: "ScheduleTests-\(UUID().uuidString)")
        defer { try? FileManager.default.removeItem(at: folder) }
        let store = JobStore(at: folder.appending(path: "jobs.json"))
        let jobs = [SwiftJob(id: "j1", project: "nest", prompt: "Tidy", settings: .everyday, ultracode: true, mode: .auto,
                             timing: .weekly(weekday: 2, hour: 1), created: Self.monday(0, 8))]
        #expect(try store.load().isEmpty)
        try store.save(jobs)
        #expect(try store.load() == jobs)
    }

    /// A stand-in for Claude Code that makes a file in its folder, then finishes.
    static let maker = #"""
    echo '{"type":"system","subtype":"init","session_id":"job-1","model":"m"}'
    while IFS= read -r line; do
      case "$line" in
        *'"type":"user"'*)
          echo made > made.txt
          echo '{"type":"assistant","message":{"id":"m1","content":[{"type":"text","text":"Made the file."}]}}'
          echo '{"type":"result","subtype":"success","is_error":false,"total_cost_usd":0.3,"session_id":"job-1"}' ;;
      esac
    done
    """#

    @Test func aDueJobRunsInAWorktreeAndLeavesYourCheckoutAlone() async throws {
        let repo = try await TempRepo()
        let support = FileManager.default.temporaryDirectory.appending(path: "ScheduleTests-\(UUID().uuidString)")
        defer { repo.remove(); try? FileManager.default.removeItem(at: support) }
        try FileManager.default.createDirectory(at: support, withIntermediateDirectories: true)
        let claude = try repo.script("claude", Self.maker)
        let job = SwiftJob(id: "j7", project: "p", prompt: "Make the file", settings: .everyday, ultracode: true, mode: .acceptEdits,
                           timing: .nextGap, created: .now)

        let result = try await JobRunner(folder: support, command: claude).run(job, in: repo.url)

        #expect(result.branch == "swift/j7")
        #expect(result.summary == "Made the file.")
        #expect(result.costUSD == 0.3)
        #expect(try await repo.git("log", "-1", "--format=%s", "swift/j7") == "Swift: Make the file")
        #expect(try await repo.git("show", "swift/j7:made.txt") == "made")
        #expect(try await repo.git("branch", "--show-current") == "main")
        #expect(!FileManager.default.fileExists(atPath: repo.url.appending(path: "made.txt").path))
        #expect(try await repo.git("worktree", "list").split(separator: "\n").count == 1)
        #expect(result.event.undo?.op == "git.branch.delete")

        try await JobRunner.undo(result.event, in: repo.url)
        await #expect(throws: CocoaError.self) { try await repo.git("rev-parse", "--verify", "swift/j7") }
    }

    @Test func swiftPicksTheFirstDueJobOnlyWhileYouAreAway() {
        let pattern = Self.pattern
        let jobs = [
            SwiftJob(id: "a", project: "p", prompt: "A", settings: .everyday, ultracode: false, mode: .acceptEdits,
                     timing: .at(Self.monday(0, 23)), created: Self.monday(0, 8)),
            SwiftJob(id: "b", project: "p", prompt: "B", settings: .everyday, ultracode: false, mode: .acceptEdits,
                     timing: .nextGap, created: Self.monday(0, 8)),
        ]
        #expect(JobRunner.next(jobs, at: Self.monday(0, 19), away: true, pattern: pattern, calendar: Self.calendar)?.id == "b")
        #expect(JobRunner.next(jobs, at: Self.monday(0, 19), away: false, pattern: pattern, calendar: Self.calendar) == nil)
        #expect(JobRunner.next(jobs, at: Self.monday(0, 10), away: true, pattern: pattern, calendar: Self.calendar) == nil)
    }

    @Test func theShiftRunsADueJobOnceAndRecordsIt() async throws {
        let repo = try await TempRepo()
        let support = FileManager.default.temporaryDirectory.appending(path: "ScheduleTests-\(UUID().uuidString)")
        defer { repo.remove(); try? FileManager.default.removeItem(at: support) }
        let store = JobStore(at: support.appending(path: "jobs.json"))
        try store.save([SwiftJob(id: "j1", project: "p", prompt: "Make the file", settings: .everyday, ultracode: false,
                                 mode: .acceptEdits, timing: .nextGap, created: Self.monday(0, 8))])
        let project = SwiftProject(id: "p", name: "P", folder: repo.url.path)
        let presence = PresenceWatch()
        let published = Published()
        let shift = JobShift(store: store, projects: [project], runner: JobRunner(folder: support, command: try repo.script("claude", Self.maker)),
                             presence: presence, pattern: Self.pattern, budget: nil, publish: { await published.add($0) })

        #expect(try await shift.tick(at: Self.monday(0, 19)) == nil)
        await presence.receive(.presenceChanged(to: "away", was: "here"))
        #expect(try await shift.tick(at: Self.monday(0, 19))?.branch == "swift/j1")
        #expect(try await shift.tick(at: Self.monday(0, 20)) == nil)

        let saved = try store.load()
        #expect(saved.first?.lastRun == Self.monday(0, 19))
        #expect(saved.first?.outcome == "On swift/j1: Made the file.")
        #expect(await published.events.map(\.topic) == [.swiftRunFinished])
    }

    @Test func eachJobKnowsWhenItRunsNext() {
        let pattern = Self.pattern
        func job(_ timing: JobTiming) -> SwiftJob {
            SwiftJob(id: "j", project: "p", prompt: "P", settings: .everyday, ultracode: false, mode: .acceptEdits,
                     timing: timing, created: Self.monday(0, 8))
        }
        let now = Self.monday(0, 10)
        #expect(job(.nextGap).nextRun(after: now, pattern: pattern, calendar: Self.calendar) == Self.monday(0, 18))
        #expect(job(.tonight).nextRun(after: now, pattern: pattern, calendar: Self.calendar) == Self.monday(0, 22))
        #expect(job(.nightly(hour: 1)).nextRun(after: now, pattern: pattern, calendar: Self.calendar) == Self.monday(1, 1))
        #expect(job(.nightly(hour: 20)).nextRun(after: now, pattern: pattern, calendar: Self.calendar) == Self.monday(0, 20))
        #expect(job(.nightly(hour: 9)).nextRun(after: now, pattern: pattern, calendar: Self.calendar) == Self.monday(5, 9))
        #expect(job(.weekly(weekday: 7, hour: 9)).nextRun(after: now, pattern: pattern, calendar: Self.calendar) == Self.monday(5, 9))
        var done = job(.at(Self.monday(1, 3)))
        done.lastRun = Self.monday(1, 3)
        #expect(done.nextRun(after: now, pattern: pattern, calendar: Self.calendar) == nil)
    }
}
