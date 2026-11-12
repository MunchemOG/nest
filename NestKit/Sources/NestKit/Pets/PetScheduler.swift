import Foundation

/// Decides each tick which mode the pets are in and which idle birds are out.
public struct PetScheduler: Sendable {
    private let settings: PetSettings
    private var nextVisit: Date?
    private var visitor: Bird?
    private var visitEnd = Date.distantPast
    private var breakBirds: Set<Bird> = []
    private var breakEnd: Date?
    private var cooldownEnd = Date.distantPast
    private var wasHidden = false
    private var livelyOut: Set<Bird>?

    /// A scheduler using `settings`.
    public init(settings: PetSettings) {
        self.settings = settings
    }

    /// The plan for `world`, given the current work `streak` in seconds.
    public mutating func plan(_ world: PetWorld, streak: TimeInterval, using rng: inout some RandomNumberGenerator) -> PetPlan {
        let now = world.now
        let idle = world.idleBirds
        let favoured = Self.favoured(in: world, settings: settings)
        if nextVisit == nil {
            nextVisit = now + .random(in: settings.visitGap, using: &rng)
        }
        func plan(_ mode: PetMode, _ out: Set<Bird>, hiding causes: Set<HideCause> = []) -> PetPlan {
            PetPlan(mode: mode, out: out.intersection(idle), favoured: favoured, hideCauses: causes)
        }

        var causes = world.hideCauses
        if let app = world.frontApp, settings.meetingApps.contains(app) {
            causes.insert(.meetingApp)
        }
        if !causes.isEmpty {
            visitor = nil
            breakBirds = []
            breakEnd = nil
            livelyOut = nil
            wasHidden = true
            return plan(.hidden, [], hiding: causes)
        }
        if wasHidden {
            wasHidden = false
            nextVisit = now + .random(in: settings.visitGap, using: &rng)
        }

        if world.secondsSinceInput >= settings.livelyAfter {
            livelyOut = idle
            return plan(.lively, idle)
        }
        if let wereOut = livelyOut {
            livelyOut = nil
            keepOneVisitor(from: wereOut.intersection(idle), favoured: favoured, now: now, using: &rng)
        }

        if breakEnd == nil, streak >= settings.breakAfter, now >= cooldownEnd {
            startBreak(idle: idle, now: now, using: &rng)
        }
        if let end = breakEnd {
            if now < end {
                return plan(.breakBuddy, breakBirds)
            }
            breakEnd = nil
            breakBirds = []
        }

        updateVisit(idle: idle, favoured: favoured, now: now, using: &rng)
        return plan(.visitor, visitor.map { [$0] } ?? [])
    }

    /// The bird the world favours: Owl late at night if idle, else the idle bird that likes the front app.
    public static func favoured(in world: PetWorld, settings: PetSettings) -> Bird? {
        let idle = world.idleBirds
        let night = world.hour >= settings.nightStartHour || world.hour < settings.nightEndHour
        if night, idle.contains(.owl) {
            return .owl
        }
        guard let app = world.frontApp else { return nil }
        return Bird.allCases.first { idle.contains($0) && BirdQuirks.of($0).apps.contains(app) }
    }

    private mutating func keepOneVisitor(from candidates: Set<Bird>, favoured: Bird?, now: Date, using rng: inout some RandomNumberGenerator) {
        guard visitor == nil, let nextVisit, now >= nextVisit else { return }
        let ordered = Bird.allCases.filter(candidates.contains)
        guard let pick = favoured.flatMap({ candidates.contains($0) ? $0 : nil }) ?? ordered.randomElement(using: &rng) else { return }
        visitor = pick
        visitEnd = now + .random(in: settings.visitLength, using: &rng)
    }

    private mutating func startBreak(idle: Set<Bird>, now: Date, using rng: inout some RandomNumberGenerator) {
        let count = min(Int.random(in: settings.breakBirds, using: &rng), idle.count)
        breakBirds = Set(Bird.allCases.filter(idle.contains).shuffled(using: &rng).prefix(count))
        let end = now + settings.breakLength
        breakEnd = end
        cooldownEnd = end + settings.breakCooldown
        visitor = nil
        nextVisit = end + .random(in: settings.visitGap, using: &rng)
    }

    private mutating func updateVisit(idle: Set<Bird>, favoured: Bird?, now: Date, using rng: inout some RandomNumberGenerator) {
        if let current = visitor, now >= visitEnd || !idle.contains(current) {
            visitor = nil
            nextVisit = now + .random(in: settings.visitGap, using: &rng)
        }
        guard visitor == nil, let due = nextVisit else { return }
        if now.timeIntervalSince(due) > settings.visitGap.upperBound {
            nextVisit = now + .random(in: settings.visitGap, using: &rng)
            return
        }
        guard now >= due else { return }
        let ordered = Bird.allCases.filter(idle.contains)
        guard let pick = favoured ?? ordered.randomElement(using: &rng) else { return }
        visitor = pick
        visitEnd = now + .random(in: settings.visitLength, using: &rng)
    }
}
