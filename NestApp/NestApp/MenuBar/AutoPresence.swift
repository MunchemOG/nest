import CoreGraphics
import Foundation
import NestKit
import Observation

/// Swift deciding by itself whether you're here: once a minute it reads how long the Mac has been idle,
/// records the minute if you were active, and tells Swift you're away only when the learned week and the idle time agree.
/// Until Owl exists, it speaks through the menu bar's presence switch.
@MainActor
@Observable
final class AutoPresence {
    let presence: PresenceSwitch
    let log: ActivityLog
    let rule = AwayRule()
    private let messages: @Sendable () -> [Date]
    private let idle: @Sendable () -> TimeInterval
    private let now: @Sendable () -> Date
    private let calendar: Calendar
    private var pattern: WorkPattern?
    private var learned: Date?
    private var loop: Task<Void, Never>?

    /// Whether you're holding Swift: you count as here however long you're idle.
    var hold = false {
        didSet { tick() }
    }
    /// What Swift makes of you right now, in a sentence.
    private(set) var status = "Swift is learning your week."

    /// How often Swift looks.
    nonisolated static let interval: Duration = .seconds(60)
    /// How often the week is learned again.
    nonisolated static let relearn: TimeInterval = 3600

    /// A watcher that speaks through `presence`, logging activity to `log` and learning from your Claude Code `messages`.
    init(
        presence: PresenceSwitch,
        log: ActivityLog,
        messages: @escaping @Sendable () -> [Date],
        idle: @escaping @Sendable () -> TimeInterval = AutoPresence.secondsIdle,
        now: @escaping @Sendable () -> Date = { .now },
        calendar: Calendar = .current
    ) {
        self.presence = presence
        self.log = log
        self.messages = messages
        self.idle = idle
        self.now = now
        self.calendar = calendar
    }

    /// How long since the last key press, click or pointer move, as the system counts it.
    nonisolated static func secondsIdle() -> TimeInterval {
        CGEventSource.secondsSinceLastEventType(.combinedSessionState, eventType: CGEventType(rawValue: ~0)!)
    }

    /// Starts looking once a minute until the app quits.
    func start() {
        guard loop == nil else { return }
        loop = Task { [weak self] in
            while !Task.isCancelled {
                self?.tick()
                try? await Task.sleep(for: Self.interval)
            }
        }
    }

    /// One look: record activity, learn the week again if it's been an hour, and tell Swift where you are.
    func tick() {
        let time = now()
        let idle = idle()
        if idle < 60 { try? log.record(activeAt: time) }
        if pattern == nil || time.timeIntervalSince(learned ?? .distantPast) >= Self.relearn {
            pattern = WorkPattern(messages: messages(), activity: (try? log.hours(now: time)) ?? [:], now: time, calendar: calendar)
            learned = time
        }
        guard let pattern else { return }
        let here = rule.presence(idle: idle, at: time, pattern: pattern, hold: hold) == "here"
        presence.isHere = here
        status = hold ? "Swift is held." : here ? "You're here. Swift waits." : "You're away. Swift may work."
    }
}
