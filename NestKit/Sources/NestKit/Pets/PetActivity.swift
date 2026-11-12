/// What a pet is doing.
public enum PetActivity: Hashable, Sendable, CaseIterable {
    /// In its menu bar spot.
    case home
    /// On its way to a perch.
    case flyingOut
    /// Sitting on a perch.
    case perched
    /// Preening on its perch.
    case preening
    /// Hopping along its perch.
    case hopping
    /// Dozing on its perch.
    case dozing
    /// Flying loops.
    case looping
    /// Chasing another pet.
    case chasing
    /// Following the pointer at a distance.
    case following
    /// Darting away from a rushing pointer.
    case fleeing
    /// On its way home.
    case flyingHome

    /// The shape its motes form while doing this.
    public var shape: PetShape {
        switch self {
        case .home, .perched, .preening, .hopping, .dozing: .glyph
        case .flyingOut, .looping, .chasing, .following, .fleeing, .flyingHome: .flight
        }
    }
}
