import Foundation

/// Each pet's state machine: turns the scheduler's plan into an intent per bird.
public struct PetBrain: Sendable {
    struct Pet: Sendable {
        var activity = PetActivity.home
        var perch: Perch?
        var target: PetPoint?
        var until = Date.distantPast
        var travel: TimeInterval = 0
        var reaction: PetReaction?
    }

    let settings: PetSettings
    var pets: [Bird: Pet] = [:]
    private var previousMode: PetMode?
    private var previousFrontApp: String?
    private var hasTicked = false

    /// A brain using `settings`.
    public init(settings: PetSettings) {
        self.settings = settings
    }

    /// Every bird's intent for this tick.
    public mutating func intents(plan: PetPlan, world: PetWorld, using rng: inout some RandomNumberGenerator) -> [Bird: PetIntent] {
        let appChanged = hasTicked && world.frontApp != previousFrontApp
        let idle = world.idleBirds
        for bird in Bird.allCases {
            var pet = pets[bird] ?? Pet()
            if plan.out.contains(bird), world.homes[bird] != nil {
                stayOut(bird, &pet, plan: plan, world: world, appChanged: appChanged, using: &rng)
            } else {
                goHome(bird, &pet, urgent: plan.mode == .hidden || !idle.contains(bird), world: world)
            }
            pets[bird] = pet
        }
        previousMode = plan.mode
        previousFrontApp = world.frontApp
        hasTicked = true
        return Dictionary(uniqueKeysWithValues: Bird.allCases.map { bird in
            let pet = pets[bird] ?? Pet()
            let target = pet.target ?? world.homes[bird] ?? PetPoint(x: 0, y: 0)
            return (bird, PetIntent(activity: pet.activity, reaction: pet.reaction, target: target, travel: pet.travel))
        })
    }

    /// Perch points held by every bird but `bird`.
    func taken(besides bird: Bird) -> [PetPoint] {
        pets.filter { $0.key != bird }.compactMap { $0.value.perch?.point }
    }

    /// Starts a flight to `perch`.
    func fly(_ pet: inout Pet, to perch: Perch, as activity: PetActivity = .flyingOut, now: Date) {
        pet.activity = activity
        pet.perch = perch
        pet.target = perch.point
        pet.travel = settings.flightTime
        pet.until = now + settings.flightTime
    }

    /// Sits on its own perch for one dwell.
    func perch(_ pet: inout Pet, quirks: BirdQuirks, now: Date, using rng: inout some RandomNumberGenerator) {
        pet.activity = .perched
        pet.target = pet.perch?.point ?? pet.target
        pet.travel = 0
        pet.until = now + .random(in: quirks.dwell, using: &rng)
    }

    private func goHome(_ bird: Bird, _ pet: inout Pet, urgent: Bool, world: PetWorld) {
        let home = world.homes[bird] ?? pet.target
        switch pet.activity {
        case .home:
            pet.target = home
            pet.travel = 0
            pet.reaction = nil
        case .flyingHome where world.now >= pet.until:
            pet.activity = .home
            pet.target = home
            pet.travel = 0
            pet.reaction = nil
        case .flyingHome:
            if urgent, pet.until > world.now + PetSettings.goHome {
                pet.travel = PetSettings.goHome
                pet.until = world.now + PetSettings.goHome
            }
        default:
            let travel = urgent ? PetSettings.goHome : previousMode == .lively ? settings.livelySettle : settings.flightTime
            pet.activity = .flyingHome
            pet.perch = nil
            pet.target = home
            pet.travel = travel
            pet.until = world.now + travel
            pet.reaction = BirdQuirks.of(bird).homeReaction
        }
    }

    private func stayOut(_ bird: Bird, _ pet: inout Pet, plan: PetPlan, world: PetWorld, appChanged: Bool, using rng: inout some RandomNumberGenerator) {
        let now = world.now
        let quirks = BirdQuirks.of(bird)
        pet.reaction = nil
        switch pet.activity {
        case .home, .flyingHome:
            if let perch = PerchChoice.choose(for: bird, plan: plan, world: world, taken: taken(besides: bird),
                                              spacing: settings.perchSpacing, using: &rng) {
                fly(&pet, to: perch, now: now)
            } else if pet.activity == .flyingHome, now >= pet.until {
                pet.activity = .home
                pet.travel = 0
            }
            return
        case .flyingOut, .fleeing:
            if now >= pet.until {
                perch(&pet, quirks: quirks, now: now, using: &rng)
            }
        case .perched:
            if now >= pet.until {
                settle(bird, &pet, quirks: quirks, plan: plan, world: world, using: &rng)
            }
        case .preening, .hopping, .dozing, .looping, .chasing, .following:
            if now >= pet.until {
                perch(&pet, quirks: quirks, now: now, using: &rng)
            }
        }
        if appChanged, quirks.curiosity >= 0.9, pet.activity != .flyingOut, let app = world.frontApp,
           let perch = world.perches.first(where: { perch in
               perch.app == app && taken(besides: bird).allSatisfy { $0.distance(to: perch.point) >= settings.perchSpacing }
           }) {
            fly(&pet, to: perch, now: now)
        }
    }

    private func settle(_ bird: Bird, _ pet: inout Pet, quirks: BirdQuirks, plan: PetPlan, world: PetWorld, using rng: inout some RandomNumberGenerator) {
        let now = world.now
        let chance = Double.random(in: 0..<1, using: &rng)
        if plan.mode == .lively, chance < 0.6 {
            let others = Bird.allCases.filter { $0 != bird && plan.out.contains($0) }.compactMap { pets[$0]?.perch?.point }
            if Bool.random(using: &rng), let quarry = others.randomElement(using: &rng) {
                act(&pet, .chasing, target: quarry, travel: settings.flightTime, quirks: quirks, now: now, using: &rng)
            } else {
                act(&pet, .looping, target: pet.target, travel: 0, quirks: quirks, now: now, using: &rng)
            }
            return
        }
        if plan.mode != .lively, chance < 0.5 {
            if quirks.habit == .perched {
                perch(&pet, quirks: quirks, now: now, using: &rng)
            } else {
                act(&pet, quirks.habit, target: pet.target, travel: 0, quirks: quirks, now: now, using: &rng)
            }
            return
        }
        let blocked = taken(besides: bird) + (pet.perch.map { [$0.point] } ?? [])
        if let next = PerchChoice.choose(for: bird, plan: plan, world: world, taken: blocked, spacing: settings.perchSpacing, using: &rng) {
            fly(&pet, to: next, now: now)
        } else {
            perch(&pet, quirks: quirks, now: now, using: &rng)
        }
    }

    private func act(_ pet: inout Pet, _ activity: PetActivity, target: PetPoint?, travel: TimeInterval, quirks: BirdQuirks, now: Date,
                     using rng: inout some RandomNumberGenerator) {
        pet.activity = activity
        pet.target = target
        pet.travel = travel
        pet.until = now + .random(in: quirks.dwell, using: &rng)
    }
}
