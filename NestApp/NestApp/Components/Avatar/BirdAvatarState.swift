/// What a bird avatar shows about the bird.
enum BirdAvatarState: String, CaseIterable, Hashable, Sendable {
    /// Quiet: just the tile.
    case resting
    /// Working: a dot in the bird's colour breathes on the corner.
    case active
    /// Paused: the tile loses its colour and shows a pause badge.
    case paused

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
        }
    }

    /// Whether the tile is drawn without colour.
    var isGrayscale: Bool { self == .paused }

    /// The word for this state.
    var word: String {
        switch self {
        case .resting: "resting"
        case .active: "working"
        case .paused: "paused"
        }
    }
}
