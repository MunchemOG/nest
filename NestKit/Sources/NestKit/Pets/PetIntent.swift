import Foundation

/// What one pet should be doing this tick, for the renderer to ease toward.
public struct PetIntent: Hashable, Sendable {
    /// What the pet is doing.
    public var activity: PetActivity
    /// A flourish on top of the activity, if any.
    public var reaction: PetReaction?
    /// Where the pet is, or is heading.
    public var target: PetPoint
    /// How long the current move to `target` takes, in seconds; zero when it is already there.
    public var travel: TimeInterval

    /// An intent from its parts.
    public init(activity: PetActivity, reaction: PetReaction? = nil, target: PetPoint, travel: TimeInterval = 0) {
        self.activity = activity
        self.reaction = reaction
        self.target = target
        self.travel = travel
    }

    /// The shape its motes form.
    public var shape: PetShape {
        activity.shape
    }
}
