import Foundation

/// The report that ends every run: status first, then the headline number, then three points (see `docs/minds/swift.md`).
public struct SwiftReport: Sendable, Equatable {
    /// How the run went.
    public let status: ReportStatus
    /// The Nest's health in one line, such as "Nest is healthy · 212 tests passing".
    public let health: String
    /// The headline number, such as "9 of 11 tasks merged."
    public let headline: String
    /// Each task's ending, in run order: `ok`, `held` or `fail`.
    public let tasks: [String]
    /// Three points: new tests, usage, and what was held or failed.
    public let points: [ReportPoint]
    /// What the run used.
    public let usage: ReportedUsage

    /// How close to the reserve counts as close: five points of the weekly limit.
    public static let nearReserve = 0.05

    /// The report for `tasks`, with `testsPassing` tests now green, whether main is `healthy`, and what was used.
    /// `highlight` is one sentence about what the run made possible, added to the headline.
    public init(tasks: [ReportedTask], testsPassing: Int, healthy: Bool, usage: ReportedUsage, highlight: String? = nil) {
        let merged = tasks.filter { $0.ending == .ok }.count
        let held = tasks.filter { $0.ending == .held }
        let failed = tasks.filter { $0.ending == .fail }
        let left = 1 - usage.reserve - usage.weekly
        status = if !healthy {
            .red
        } else if failed.contains(where: { $0.guess == nil }) || left < Self.nearReserve {
            .amber
        } else {
            .green
        }
        health = "Nest is \(healthy ? "healthy" : "broken") · \(testsPassing) tests passing"
        headline = "\(merged) of \(tasks.count) \(tasks.count == 1 ? "task" : "tasks") merged." + (highlight.map { " \($0)" } ?? "")
        self.tasks = tasks.map(\.ending.rawValue)
        self.usage = usage
        let added = tasks.map(\.testsAdded).reduce(0, +)
        let usageText = left < Self.nearReserve
            ? "of the weekly limit used. \(Self.percent(max(0, left))) left before the reserve."
            : "of the weekly limit used. Your robotics reserve is untouched."
        points = [
            ReportPoint(figure: "+\(added)", text: "new tests; the safety net is now \(testsPassing)."),
            ReportPoint(figure: Self.percent(usage.weekly), text: usageText),
            Self.troublePoint(held: held, failed: failed),
        ]
    }

    /// The `swift.report.ready` event for this report; only red pings, the rest wait for a calm moment.
    public func event(at time: Date = .now) -> NestEvent {
        let summary = "Swift: \(status.rawValue.capitalized). \(headline)"
        return NestEvent(
            id: EventID.make(at: time), ts: time, sender: .bird(.swift), kind: .report, topic: .swiftReportReady,
            summary: summary.count > NestEvent.summaryMaxLength ? String(summary.prefix(NestEvent.summaryMaxLength - 1)) + "…" : summary,
            data: [
                "status": .string(status.rawValue),
                "health": .string(health),
                "headline": .string(headline),
                "tasks": .array(tasks.map { .string($0) }),
                "points": .array(points.map { .object(["figure": .string($0.figure), "text": .string($0.text)]) }),
                "usage": .object(["weekly": .number(usage.weekly), "five_hour": .number(usage.fiveHour), "cost_usd": .number(usage.costUSD)]),
            ],
            undo: nil, causedBy: nil, attention: status == .red ? .ping : .calm
        )
    }

    private static func troublePoint(held: [ReportedTask], failed: [ReportedTask]) -> ReportPoint {
        if let first = held.first {
            return ReportPoint(figure: "\(held.count) held", text: explanation(of: first))
        }
        if let first = failed.first {
            return ReportPoint(figure: "\(failed.count) failed", text: explanation(of: first))
        }
        return ReportPoint(figure: "0 held", text: "Nothing was held or rolled back.")
    }

    private static func explanation(of task: ReportedTask) -> String {
        let why = task.why ?? "\(task.id) did not merge"
        guard let guess = task.guess else { return "\(why). No guess yet." }
        return "\(why). Best guess: \(guess)" + (task.confidence.map { ", \(percent($0))." } ?? ".")
    }

    private static func percent(_ share: Double) -> String { "\(Int((share * 100).rounded()))%" }
}
