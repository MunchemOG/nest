import NestKit

/// What a bird avatar shows about the bird.
enum BirdAvatarState: String, CaseIterable, Hashable, Sendable {
    /// Quiet: just the tile.
    case resting
    /// Working: a dot in the bird's colour breathes on the corner.
    case active
    /// Paused: the tile loses its colour and shows a pause badge.
    case paused
    /// Not built or not heard from yet: the tile loses its colour and shows a sleeping badge.
    case asleep

    /// The avatar state for a bird's status.
    init(_ status: BirdStatus) {
        switch status {
        case .active: self = .active
        case .paused: self = .paused
        case .resting: self = .resting
        case .asleep: self = .asleep
        }
    }

    /// What sits on the tile's corner.
    enum Badge: Hashable, Sendable {
        case none
        case dot
        case symbol(String)
    }

    /// The badge for this state.
    var badge: Badge {
        switch self {
        case .resting: .none
        case .active: .dot
        case .paused: .symbol("pause.fill")
        case .asleep: .symbol("moon.zzz.fill")
        }
    }

    /// Whether the tile is drawn without colour.
    var isGrayscale: Bool { self == .paused || self == .asleep }

    /// The word for this state.
    var word: String {
        switch self {
        case .resting: "resting"
        case .active: "working"
        case .paused: "paused"
        case .asleep: "asleep"
        }
    }
}
