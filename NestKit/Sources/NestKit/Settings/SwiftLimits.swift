/// The limits you set for Swift: how much of the week it may use and how full the five-hour window may get.
public struct SwiftLimits: Sendable, Equatable, Codable {
    /// The most of the weekly limit Swift may reach (0 to 1).
    public var weeklyCap: Double
    /// How full the five-hour window may get before Swift waits for it to reset (0 to 1).
    public var fiveHourCap: Double

    /// Limits that stop Swift at `weeklyCap` of the week and `fiveHourCap` of the five-hour window.
    public init(weeklyCap: Double, fiveHourCap: Double) {
        self.weeklyCap = weeklyCap
        self.fiveHourCap = fiveHourCap
    }

    /// The rules these limits make, with `reserve` kept back for you and `blocked` hours left alone.
    public func rules(reserve: Double, blocked: [BlockedHours] = []) -> BudgetRules {
        BudgetRules(blocked: blocked, reserve: reserve, fiveHourCeiling: fiveHourCap, weeklyCap: weeklyCap)
    }

    /// Where Swift starts before you set anything: three quarters of the week, nearly all of the five hours.
    public static let standard = SwiftLimits(weeklyCap: 0.75, fiveHourCap: 0.95)
}
