/// Picks where a pet lands.
public enum PerchChoice {
    /// The perch for `bird`, keeping `spacing` points from every point in `taken`, or nil if none is free.
    public static func choose(
        for bird: Bird,
        plan: PetPlan,
        world: PetWorld,
        taken: [PetPoint],
        spacing: Double,
        using rng: inout some RandomNumberGenerator
    ) -> Perch? {
        let free = world.perches.filter { perch in
            taken.allSatisfy { $0.distance(to: perch.point) >= spacing }
        }
        if plan.favoured == bird, let app = world.frontApp,
           let perch = mostPreferred(free.filter { $0.app == app && [.dockIcon, .windowTop].contains($0.kind) }, using: &rng) {
            return perch
        }
        if plan.mode == .breakBuddy {
            return free.min { $0.point.distance(to: world.pointer) < $1.point.distance(to: world.pointer) }
        }
        return mostPreferred(free, using: &rng)
    }

    private static func mostPreferred(_ perches: [Perch], using rng: inout some RandomNumberGenerator) -> Perch? {
        guard let best = perches.map(\.kind).min() else { return nil }
        return perches.filter { $0.kind == best }.randomElement(using: &rng)
    }
}
