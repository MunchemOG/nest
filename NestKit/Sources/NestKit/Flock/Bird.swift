/// One of the six birds in the flock; its raw value is its id on the event bus.
public enum Bird: String, CaseIterable, Hashable, Sendable {
    /// Keeper of space.
    case wren
    /// The builder.
    case swift
    /// The inventor.
    case crow
    /// The eyes.
    case owl
    /// The second brain.
    case magpie
    /// The showcase.
    case peacock

    /// The bird's name as people read it.
    public var name: String {
        switch self {
        case .wren: "Wren"
        case .swift: "Swift"
        case .crow: "Crow"
        case .owl: "Owl"
        case .magpie: "Magpie"
        case .peacock: "Peacock"
        }
    }

    /// The bird's job in a few words, from the master plan.
    public var role: String {
        switch self {
        case .wren: "Keeper of space"
        case .swift: "Builder"
        case .crow: "Inventor"
        case .owl: "Eyes"
        case .magpie: "Second brain"
        case .peacock: "Showcase"
        }
    }

    /// The phase of the build order (`docs/master-plan.md`) in which the bird is built and wakes up.
    public var buildPhase: Int {
        switch self {
        case .swift: 2
        case .wren: 3
        case .magpie: 4
        case .crow: 5
        case .owl: 6
        case .peacock: 7
        }
    }

    /// The bird's own colour, used for nothing else.
    public var color: NestColor {
        switch self {
        case .wren: .flockWren
        case .swift: .flockSwift
        case .crow: .flockCrow
        case .owl: .flockOwl
        case .magpie: .flockMagpie
        case .peacock: .flockPeacock
        }
    }

    /// A 14% wash of the bird's colour, for its bubbles, tags and resting glow.
    public var tint: NestColor {
        switch self {
        case .wren: .flockWrenTint
        case .swift: .flockSwiftTint
        case .crow: .flockCrowTint
        case .owl: .flockOwlTint
        case .magpie: .flockMagpieTint
        case .peacock: .flockPeacockTint
        }
    }

    /// The bird's glyph assets.
    public var glyph: Glyph {
        Glyph(base: rawValue)
    }
}
