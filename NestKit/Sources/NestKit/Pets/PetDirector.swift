import Foundation

/// Pet mode's one entry point: each tick turns a snapshot of the Mac into an intent per bird.
public struct PetDirector: Sendable {
    private var tracker: ActivityTracker
    private var scheduler: PetScheduler
    private var brain: PetBrain
    private var rng: PetRandom

    /// The scheduler's latest plan.
    public private(set) var plan = PetPlan(mode: .visitor, out: [], favoured: nil, hideCauses: [])

    /// A director using `settings`, whose randomness replays exactly for `seed`.
    public init(settings: PetSettings = PetSettings(), seed: UInt64) {
        tracker = ActivityTracker(breakPause: settings.breakPause)
        scheduler = PetScheduler(settings: settings)
        brain = PetBrain(settings: settings)
        rng = PetRandom(seed: seed)
    }

    /// Every bird's intent for `world`.
    public mutating func tick(_ world: PetWorld) -> [Bird: PetIntent] {
        let streak = tracker.streak(now: world.now, secondsSinceInput: world.secondsSinceInput)
        plan = scheduler.plan(world, streak: streak, using: &rng)
        return brain.intents(plan: plan, world: world, using: &rng)
    }
}
