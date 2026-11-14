import Foundation

/// Swift's usage log, kept in an SQLite file on this Mac: what each session cost and how full the limits were.
public actor UsageLog {
    private let database: SQLiteDatabase

    /// The log stored in the file at `url`, created empty if the file is new.
    public init(at url: URL) throws {
        database = try SQLiteDatabase(at: url)
        try database.execute("""
            CREATE TABLE IF NOT EXISTS sessions (
                task TEXT NOT NULL,
                started INTEGER NOT NULL,
                ended INTEGER NOT NULL,
                cost_microdollars INTEGER NOT NULL,
                five_hour TEXT,
                five_hour_resets INTEGER,
                weekly TEXT,
                weekly_resets INTEGER
            )
            """)
    }

    /// Logs one session of `task`.
    public func record(task: String, usage: SessionUsage, started: Date, ended: Date) throws {
        let limits = usage.limits
        try database.execute(
            "INSERT INTO sessions VALUES (?, ?, ?, ?, ?, ?, ?, ?)",
            [.text(task), .integer(Self.millis(started)), .integer(Self.millis(ended)),
             .integer(Int((usage.costUSD * 1_000_000).rounded())),
             limits.map { .text(String($0.fiveHour)) } ?? .null, limits.map { .integer(Self.millis($0.fiveHourResets)) } ?? .null,
             limits.map { .text(String($0.weekly)) } ?? .null, limits.map { .integer(Self.millis($0.weeklyResets)) } ?? .null]
        )
    }

    /// Every logged session, oldest first.
    public func entries() throws -> [UsageEntry] {
        try database.rows("SELECT * FROM sessions ORDER BY started, rowid").compactMap { row in
            guard row.count == 8, let task = row[0].text, let started = row[1].integer, let ended = row[2].integer,
                  let cost = row[3].integer else { return nil }
            var limits: LimitSnapshot?
            if let five = row[4].text.flatMap(Double.init), let fiveResets = row[5].integer,
               let week = row[6].text.flatMap(Double.init), let weekResets = row[7].integer {
                limits = LimitSnapshot(fiveHour: five, fiveHourResets: Self.date(fiveResets),
                                       weekly: week, weeklyResets: Self.date(weekResets))
            }
            return UsageEntry(task: task, started: Self.date(started), ended: Self.date(ended),
                              costUSD: Double(cost) / 1_000_000, limits: limits)
        }
    }

    /// The report for every session that started between `start` and `end`.
    public func report(from start: Date, to end: Date) throws -> UsageReport {
        UsageReport(entries: try entries().filter { $0.started >= start && $0.started <= end })
    }

    /// Your own share of the weekly limit on each logged day, oldest first: what the day's sessions don't explain.
    public func yourUse(byDayIn calendar: Calendar = .current) throws -> [DayUse] {
        let days = Dictionary(grouping: try entries()) { calendar.startOfDay(for: $0.started) }
        return days.keys.sorted().map { DayUse(day: $0, used: UsageReport(entries: days[$0] ?? []).chatsWeekly) }
    }

    private static func millis(_ date: Date) -> Int { Int((date.timeIntervalSince1970 * 1000).rounded()) }
    private static func date(_ millis: Int) -> Date { Date(timeIntervalSince1970: Double(millis) / 1000) }
}
