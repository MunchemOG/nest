import Foundation

/// One snapshot of everything the pets react to.
public struct PetWorld: Sendable {
    /// The time of the snapshot.
    public var now: Date
    /// What the app knows about each bird.
    public var flock: FlockState
    /// Seconds since the last keyboard or pointer input.
    public var secondsSinceInput: TimeInterval
    /// The bundle id of the front app, if any.
    public var frontApp: String?
    /// The local hour, 0 to 23.
    public var hour: Int
    /// Where the pointer is.
    public var pointer: PetPoint
    /// How fast the pointer is moving, in points a second.
    public var pointerSpeed: Double
    /// Every place a bird could land right now.
    public var perches: [Perch]
    /// Each bird's spot in the menu bar.
    public var homes: [Bird: PetPoint]
    /// Reasons the sensors give for keeping every bird home.
    public var hideCauses: Set<HideCause>

    /// A snapshot from every input.
    public init(
        now: Date,
        flock: FlockState,
        secondsSinceInput: TimeInterval,
        frontApp: String?,
        hour: Int,
        pointer: PetPoint,
        pointerSpeed: Double,
        perches: [Perch],
        homes: [Bird: PetPoint],
        hideCauses: Set<HideCause>
    ) {
        self.now = now
        self.flock = flock
        self.secondsSinceInput = secondsSinceInput
        self.frontApp = frontApp
        self.hour = hour
        self.pointer = pointer
        self.pointerSpeed = pointerSpeed
        self.perches = perches
        self.homes = homes
        self.hideCauses = hideCauses
    }

    /// The birds with no work right now, resting or asleep: the only ones that may come out.
    public var idleBirds: Set<Bird> {
        Set(Bird.allCases.filter { [.resting, .asleep].contains(flock[$0].status(at: now)) })
    }
}
