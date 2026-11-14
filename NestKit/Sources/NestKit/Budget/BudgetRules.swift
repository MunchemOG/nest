import Foundation

/// Swift's simple budget: blocked hours, a share of the weekly limit kept back for you, and a full five-hour window.
public struct BudgetRules: Sendable, Equatable {
    /// Hours Swift never runs in.
    public let blocked: [BlockedHours]
    /// The share of the weekly limit Swift never touches (0 to 1).
    public let reserve: Double
    /// How full the five-hour window may be before Swift waits for it to reset (0 to 1).
    public let fiveHourCeiling: Double

    /// Rules that keep `reserve` of the week back, block `blocked`, and wait once the five-hour window reaches `fiveHourCeiling`.
    public init(blocked: [BlockedHours] = [], reserve: Double, fiveHourCeiling: Double = 0.95) {
        self.blocked = blocked
        self.reserve = reserve
        self.fiveHourCeiling = fiveHourCeiling
    }

    /// Whether a task expected to use `nextTask` of the weekly limit may start at `time`, with the limits at `limits`.
    public func decide(at time: Date, limits: LimitSnapshot?, nextTask: Double, calendar: Calendar) -> BudgetDecision {
        let parts = calendar.dateComponents([.weekday, .hour, .minute], from: time)
        let minute = (parts.hour ?? 0) * 60 + (parts.minute ?? 0)
        if let hours = blocked.first(where: { $0.contains(weekday: parts.weekday ?? 0, minute: minute) }) {
            return .pause("\(hours.reason) until \(String(format: "%02d:%02d", hours.to / 60, hours.to % 60)).")
        }
        guard let limits else { return .run }
        if limits.fiveHour >= fiveHourCeiling {
            return .pause("The five-hour limit is nearly full; it resets at \(Self.clock(limits.fiveHourResets, calendar)).")
        }
        if limits.weekly + nextTask > 1 - reserve + 1e-9 {
            return .pause("Keeping the reserve: \(Self.percent(limits.weekly)) of the week is used, the next task needs about "
                          + "\(Self.percent(nextTask)), and \(Self.percent(reserve)) is kept back.")
        }
        return .run
    }

    private static func percent(_ share: Double) -> String { "\(Int((share * 100).rounded()))%" }

    private static func clock(_ date: Date, _ calendar: Calendar) -> String {
        let parts = calendar.dateComponents([.hour, .minute], from: date)
        return String(format: "%02d:%02d", parts.hour ?? 0, parts.minute ?? 0)
    }
}
