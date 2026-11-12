import Foundation

/// The pointer rules: how each out bird reacts to the pointer after it has moved this tick.
extension PetBrain {
    /// The activities in which a bird notices the pointer.
    static let noticing: Set<PetActivity> = [.perched, .preening, .hopping, .dozing, .following, .looping]

    /// Applies the first matching pointer rule to each out bird, updating its intent.
    mutating func reactToPointer(plan: PetPlan, world: PetWorld, intents: inout [Bird: PetIntent], using rng: inout some RandomNumberGenerator) {
        let now = world.now
        if world.pointerSpeed >= settings.stillSpeed || stillSince == nil {
            stillSince = now
        }
        let still = now.timeIntervalSince(stillSince ?? now)
        for bird in Bird.allCases where plan.out.contains(bird) {
            guard var pet = pets[bird], Self.noticing.contains(pet.activity), let point = pet.target else { continue }
            let quirks = BirdQuirks.of(bird)
            if let home = pet.fledFrom, now >= pet.returnAt {
                pet.fledFrom = nil
                if taken(besides: bird).allSatisfy({ $0.distance(to: home.point) >= settings.perchSpacing }) {
                    fly(&pet, to: home, now: now)
                }
                pets[bird] = pet
                intents[bird] = intent(for: pet, fallback: point)
                continue
            }
            let d = world.pointer.distance(to: point)
            if d <= quirks.fleeDistance, world.pointerSpeed >= quirks.rushSpeed {
                flee(bird, &pet, quirks: quirks, plan: plan, world: world, using: &rng)
                pets[bird] = pet
                intents[bird] = intent(for: pet, fallback: point)
                continue
            }
            var intent = intents[bird] ?? intent(for: pet, fallback: point)
            if d <= settings.hoverRadius, world.pointerSpeed < settings.stillSpeed {
                if quirks.approachesStillPointer, quirks.bravery >= 0.9, still >= settings.sitAfter {
                    intent = PetIntent(activity: .perched, reaction: .sitOnPointer, target: world.pointer)
                } else {
                    intent.reaction = quirks.hover
                }
            } else if quirks.approachesStillPointer, d <= settings.approachRadius, still >= settings.approachAfter {
                intent = PetIntent(activity: .hopping, reaction: .hopCloser,
                                   target: Self.point(settings.hoverRadius, from: world.pointer, toward: point))
            } else if quirks.followsPointer, d <= settings.approachRadius, world.pointerSpeed >= settings.stillSpeed {
                intent = PetIntent(activity: .following, target: Self.point(settings.followDistance, from: world.pointer, toward: point))
            } else if let near = quirks.near, d <= settings.approachRadius {
                intent.reaction = near
            }
            intents[bird] = intent
        }
    }

    private func flee(_ bird: Bird, _ pet: inout Pet, quirks: BirdQuirks, plan: PetPlan, world: PetWorld,
                      using rng: inout some RandomNumberGenerator) {
        var away = world
        away.perches = world.perches.filter { $0.point.distance(to: world.pointer) > 2 * quirks.fleeDistance }
        let blocked = taken(besides: bird) + (pet.perch.map { [$0.point] } ?? [])
        guard let refuge = PerchChoice.choose(for: bird, plan: plan, world: away, taken: blocked,
                                              spacing: settings.perchSpacing, using: &rng) else {
            pet.reaction = quirks.rush
            return
        }
        let fled = pet.perch
        fly(&pet, to: refuge, as: .fleeing, now: world.now)
        pet.reaction = quirks.rush
        if quirks.returnsAfterFleeing {
            pet.fledFrom = fled
            pet.returnAt = world.now + quirks.dwell.lowerBound
        }
    }

    private func intent(for pet: Pet, fallback: PetPoint) -> PetIntent {
        PetIntent(activity: pet.activity, reaction: pet.reaction, target: pet.target ?? fallback, travel: pet.travel)
    }

    /// The point `distance` from `origin` in the direction of `other`.
    static func point(_ distance: Double, from origin: PetPoint, toward other: PetPoint) -> PetPoint {
        let length = origin.distance(to: other)
        guard length > 0 else { return PetPoint(x: origin.x, y: origin.y + distance) }
        return PetPoint(x: origin.x + (other.x - origin.x) / length * distance, y: origin.y + (other.y - origin.y) / length * distance)
    }
}
