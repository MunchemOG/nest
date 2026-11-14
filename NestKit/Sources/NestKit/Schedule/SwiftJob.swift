import Foundation

/// Work you scheduled for Swift: a prompt for Claude Code in one project, how it runs, and when.
public struct SwiftJob: Sendable, Equatable, Codable, Identifiable {
    /// The job's id, which also names its branch.
    public let id: String
    /// The project's id.
    public var project: String
    /// What Claude Code is asked to do.
    public var prompt: String
    /// The model and effort it runs on.
    public var settings: RunSettings
    /// Whether it runs as Claude Code's multi-agent Ultracode.
    public var ultracode: Bool
    /// How Claude Code may act; anything it would ask about is refused, since you're away.
    public var mode: PermissionMode
    /// When it runs.
    public var timing: JobTiming
    /// When you scheduled it.
    public let created: Date
    /// When it last ran, if it has.
    public var lastRun: Date?
    /// What came of its last run, in a line.
    public var outcome: String?

    /// A job with these fields.
    public init(id: String, project: String, prompt: String, settings: RunSettings, ultracode: Bool, mode: PermissionMode,
                timing: JobTiming, created: Date, lastRun: Date? = nil, outcome: String? = nil) {
        self.id = id
        self.project = project
        self.prompt = prompt
        self.settings = settings
        self.ultracode = ultracode
        self.mode = mode
        self.timing = timing
        self.created = created
        self.lastRun = lastRun
        self.outcome = outcome
    }

    /// The branch its work lands on.
    public var branch: String { "swift/\(id)" }

    /// Its prompt's first line, short enough for a row.
    public var title: String {
        let line = prompt.split(separator: "\n").first.map(String.init) ?? prompt
        return line.count > 60 ? String(line.prefix(59)) + "…" : line
    }

    /// Whether it's done for good: a one-off that has run.
    public var isFinished: Bool { !timing.repeats && lastRun != nil }

    /// When it will next run after `now`, given when you work, or nil if it never will again.
    public func nextRun(after now: Date, pattern: WorkPattern, calendar: Calendar = .current) -> Date? {
        if isFinished { return nil }
        func gap(from start: Date) -> Date? { pattern.nextGap(after: max(start, now)) }
        func at(hour: Int, on day: Date) -> Date? { calendar.date(bySettingHour: hour, minute: 0, second: 0, of: day) }
        func inWindow(_ next: Date, _ start: Date) -> Bool { next.timeIntervalSince(start) < Double(JobTiming.window * 3600) }
        switch timing {
        case .nextGap:
            return gap(from: now)
        case .tonight:
            return at(hour: JobTiming.tonightHour, on: created).flatMap(gap)
        case .at(let time):
            return max(time, now)
        case .nightly(let hour):
            for offset in 0..<8 {
                guard let day = calendar.date(byAdding: .day, value: offset, to: now), let start = at(hour: hour, on: day),
                      let next = gap(from: start), inWindow(next, start) else { continue }
                if offset == 0, let lastRun, calendar.isDate(lastRun, inSameDayAs: now) { continue }
                return next
            }
            return nil
        case .weekly(let weekday, let hour):
            for offset in 0..<15 {
                guard let day = calendar.date(byAdding: .day, value: offset, to: now),
                      calendar.component(.weekday, from: day) == weekday, let start = at(hour: hour, on: day),
                      let next = gap(from: start), inWindow(next, start) else { continue }
                if offset == 0, let lastRun, calendar.isDate(lastRun, inSameDayAs: now) { continue }
                return next
            }
            return nil
        }
    }

    /// Whether it should run at `now`, given when you work.
    public func isDue(at now: Date, pattern: WorkPattern, calendar: Calendar = .current) -> Bool {
        let gap = !pattern.isYours(now)
        let ranLately = lastRun.map { now.timeIntervalSince($0) < Double(JobTiming.window * 2 * 3600) } ?? false
        let hour = calendar.component(.hour, from: now)
        func inWindow(_ from: Int) -> Bool { (hour - from + 24) % 24 < JobTiming.window }
        switch timing {
        case .nextGap:
            return lastRun == nil && gap
        case .tonight:
            let start = calendar.date(bySettingHour: JobTiming.tonightHour, minute: 0, second: 0, of: created) ?? created
            return lastRun == nil && now >= start && gap
        case .at(let time):
            return lastRun == nil && now >= time
        case .nightly(let from):
            return !ranLately && inWindow(from) && gap
        case .weekly(let weekday, let from):
            return !ranLately && calendar.component(.weekday, from: now) == weekday && inWindow(from) && gap
        }
    }
}
