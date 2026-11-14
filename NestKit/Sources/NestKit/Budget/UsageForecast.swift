import Foundation

/// Forecasts how much of the weekly limit you will need yourself, learned from the days you have logged.
/// Each weekday is forecast as the most you have ever used on that weekday, with a margin, so a heavy robotics
/// Thursday is planned for every Thursday. A weekday never seen yet gets the most you used on any day.
public struct UsageForecast: Sendable {
    /// The days learned from.
    public let history: [DayUse]
    /// The calendar weekdays are read in.
    public let calendar: Calendar

    /// How far above your heaviest day the forecast sits.
    public static let margin = 1.3

    /// A forecast learned from `history`.
    public init(history: [DayUse], calendar: Calendar = .current) {
        self.history = history
        self.calendar = calendar
    }

    /// What you are forecast to use on `day`.
    public func forDay(_ day: Date) -> Double {
        let weekday = calendar.component(.weekday, from: day)
        let same = history.filter { calendar.component(.weekday, from: $0.day) == weekday }.map(\.used)
        return ((same.isEmpty ? history.map(\.used) : same).max() ?? 0) * Self.margin
    }

    /// What to keep back for you from `start` until the week resets at `resets`: every day left, today included.
    /// With no history yet, it is `fallback`, the fixed reserve.
    public func reserve(from start: Date, until resets: Date, orElse fallback: Double = 0) -> Double {
        guard !history.isEmpty else { return fallback }
        var total = 0.0
        var day = calendar.startOfDay(for: start)
        while day < resets {
            total += forDay(day)
            guard let next = calendar.date(byAdding: .day, value: 1, to: day) else { break }
            day = next
        }
        return total
    }
}
