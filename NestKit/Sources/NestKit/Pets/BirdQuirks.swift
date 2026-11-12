import Foundation

/// One bird's pet personality as numbers, from the pet mode spec.
public struct BirdQuirks: Hashable, Sendable {
    /// How little the pointer scares it, 0 to 1.
    public var bravery: Double
    /// How keen it is on what's new, 0 to 1.
    public var curiosity: Double
    /// How close a rushing pointer must come before it flees, in points.
    public var fleeDistance: Double
    /// How fast the pointer must move to count as rushing it, in points a second.
    public var rushSpeed: Double
    /// How long it stays doing one thing, in seconds.
    public var dwell: ClosedRange<TimeInterval>
    /// What it does when it settles on a perch.
    public var habit: PetActivity
    /// Its reaction to a still pointer on top of it.
    public var hover: PetReaction
    /// Its reaction to a rushing pointer.
    public var rush: PetReaction
    /// Its reaction to a pointer nearby, if any.
    public var near: PetReaction?
    /// Whether it hops toward a still pointer.
    public var approachesStillPointer: Bool
    /// Whether it follows a moving pointer.
    public var followsPointer: Bool
    /// Whether it flies back to its perch after fleeing.
    public var returnsAfterFleeing: Bool
    /// Its reaction while flying home, if any.
    public var homeReaction: PetReaction?
    /// Bundle ids of the apps it likes to perch on.
    public var apps: Set<String>

    /// The quirks of `bird`.
    public static func of(_ bird: Bird) -> BirdQuirks {
        switch bird {
        case .wren:
            BirdQuirks(bravery: 0.9, curiosity: 0.5, fleeDistance: 40, rushSpeed: 1500, dwell: 4...10,
                       habit: .hopping, hover: .hopCloser, rush: .dartAway, near: nil,
                       approachesStillPointer: true, followsPointer: false, returnsAfterFleeing: false, homeReaction: nil,
                       apps: ["com.apple.finder", "com.apple.systempreferences"])
        case .swift:
            BirdQuirks(bravery: 0.1, curiosity: 0.3, fleeDistance: 160, rushSpeed: 400, dwell: 2...5,
                       habit: .looping, hover: .tiltHead, rush: .dartAway, near: nil,
                       approachesStillPointer: false, followsPointer: false, returnsAfterFleeing: true, homeReaction: nil,
                       apps: ["com.apple.dt.Xcode", "com.microsoft.VSCode", "com.todesktop.230313mzl4w4u92", "com.apple.Terminal"])
        case .crow:
            BirdQuirks(bravery: 0.6, curiosity: 1.0, fleeDistance: 100, rushSpeed: 900, dwell: 5...12,
                       habit: .perched, hover: .tiltHead, rush: .dartAway, near: nil,
                       approachesStillPointer: false, followsPointer: true, returnsAfterFleeing: false, homeReaction: nil,
                       apps: ["com.apple.Safari", "com.google.Chrome", "company.thebrowser.Browser", "org.mozilla.firefox"])
        case .owl:
            BirdQuirks(bravery: 0.8, curiosity: 0.2, fleeDistance: 24, rushSpeed: 3000, dwell: 20...60,
                       habit: .dozing, hover: .blink, rush: .dartAway, near: .watch,
                       approachesStillPointer: false, followsPointer: false, returnsAfterFleeing: false, homeReaction: nil,
                       apps: [])
        case .magpie:
            BirdQuirks(bravery: 0.7, curiosity: 0.8, fleeDistance: 80, rushSpeed: 1000, dwell: 4...9,
                       habit: .hopping, hover: .stealSparkle, rush: .dartAway, near: nil,
                       approachesStillPointer: true, followsPointer: false, returnsAfterFleeing: false, homeReaction: .carryGlint,
                       apps: ["com.apple.Notes", "md.obsidian"])
        case .peacock:
            BirdQuirks(bravery: 0.5, curiosity: 0.4, fleeDistance: 120, rushSpeed: 700, dwell: 8...15,
                       habit: .preening, hover: .fanTail, rush: .huff, near: nil,
                       approachesStillPointer: false, followsPointer: false, returnsAfterFleeing: false, homeReaction: nil,
                       apps: ["com.figma.Desktop", "com.bohemiancoding.sketch3"])
        }
    }
}
