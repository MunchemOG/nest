/// The scheduler's decision for one tick: the mode and who is out.
public struct PetPlan: Hashable, Sendable {
    /// The mode in force.
    public var mode: PetMode
    /// The birds that should be out of the menu bar.
    public var out: Set<Bird>
    /// The bird the front app or the hour favours, if any.
    public var favoured: Bird?
    /// Why the pets are hidden; empty unless the mode is hidden.
    public var hideCauses: Set<HideCause>

    /// A plan from its parts.
    public init(mode: PetMode, out: Set<Bird>, favoured: Bird?, hideCauses: Set<HideCause>) {
        self.mode = mode
        self.out = out
        self.favoured = favoured
        self.hideCauses = hideCauses
    }
}
