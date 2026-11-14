import Foundation

/// A stretch of time in the usage log: each task's cost and share of the limits, your chats' share, and what Claude reported.
///
/// Claude reports how full each limit is during every session. Between two back-to-back sessions nothing else can run,
/// so the rise there is Swift's own and sets how much of a limit a dollar buys. Each task's share is its cost at that rate;
/// whatever rise is left between sessions is your own chats.
public struct UsageReport: Sendable, Equatable {
    /// Each task, in the order it ran.
    public let tasks: [TaskUsage]
    /// The cost of every task, as Claude reported it, in US dollars.
    public let costUSD: Double
    /// How much of the weekly limit one dollar of Swift's work used.
    public let weeklyPerDollar: Double
    /// How much of the five-hour limit one dollar of Swift's work used.
    public let fiveHourPerDollar: Double
    /// Your own chats' share of the weekly limit between the first and last session.
    public let chatsWeekly: Double
    /// Your own chats' share of the five-hour limit between the first and last session.
    public let chatsFiveHour: Double
    /// How far the weekly limit filled between the first and last session, as Claude reported it.
    public let reportedWeekly: Double
    /// How far the five-hour limit filled between the first and last session, as Claude reported it.
    public let reportedFiveHour: Double

    /// Two sessions this close together leave no room for anything else.
    public static let backToBack: Double = 120

    /// The report for `entries`, in the order they ran.
    public init(entries: [UsageEntry]) {
        let measured = entries.filter { $0.limits != nil }
        let pairs = zip(measured, measured.dropFirst()).map { ($0, $1) }
        func rise(_ pair: (UsageEntry, UsageEntry), _ window: KeyPath<LimitSnapshot, Double>,
                  _ resets: KeyPath<LimitSnapshot, Date>) -> Double {
            guard let a = pair.0.limits, let b = pair.1.limits else { return 0 }
            return LimitSnapshot.used(from: a[keyPath: window], earlierResets: a[keyPath: resets],
                                      to: b[keyPath: window], laterResets: b[keyPath: resets])
        }
        let closePairs = pairs.filter { $0.1.started.timeIntervalSince($0.0.ended) <= Self.backToBack }
        let ratePairs = closePairs.isEmpty ? pairs : closePairs
        let rateCost = ratePairs.map(\.0.costUSD).reduce(0, +)
        func rate(_ window: KeyPath<LimitSnapshot, Double>, _ resets: KeyPath<LimitSnapshot, Date>) -> Double {
            rateCost > 0 ? ratePairs.map { rise($0, window, resets) }.reduce(0, +) / rateCost : 0
        }
        let weekRate = rate(\.weekly, \.weeklyResets)
        let fiveRate = rate(\.fiveHour, \.fiveHourResets)
        let weekRises = pairs.map { rise($0, \.weekly, \.weeklyResets) }
        let fiveRises = pairs.map { rise($0, \.fiveHour, \.fiveHourResets) }
        weeklyPerDollar = weekRate
        fiveHourPerDollar = fiveRate
        reportedWeekly = weekRises.reduce(0, +)
        reportedFiveHour = fiveRises.reduce(0, +)
        chatsWeekly = zip(pairs, weekRises).map { max(0, $1 - $0.0.costUSD * weekRate) }.reduce(0, +)
        chatsFiveHour = zip(pairs, fiveRises).map { max(0, $1 - $0.0.costUSD * fiveRate) }.reduce(0, +)
        tasks = entries.map { entry in
            TaskUsage(task: entry.task, costUSD: entry.costUSD, weekly: entry.costUSD * weekRate, fiveHour: entry.costUSD * fiveRate)
        }
        costUSD = entries.map(\.costUSD).reduce(0, +)
    }
}
