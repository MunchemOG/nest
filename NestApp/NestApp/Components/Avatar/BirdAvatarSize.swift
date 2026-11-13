import NestKit

/// How big a bird avatar is drawn, from the spacing and radius tokens.
enum BirdAvatarSize: String, CaseIterable, Hashable, Sendable {
    /// The mini icon in rows, panels and the command bar.
    case small
    /// Cards and chat.
    case medium
    /// A bird's close-up.
    case large

    /// The tile's width and height.
    var side: Double {
        switch self {
        case .small: NestSpace.s5
        case .medium: NestSpace.s7
        case .large: NestSpace.s9
        }
    }

    /// The tile's corner radius.
    var cornerRadius: Double {
        switch self {
        case .small: NestRadius.sm
        case .medium: NestRadius.lg
        case .large: NestRadius.tile
        }
    }

    /// The diameter of the status badge on the tile's corner.
    var badge: Double {
        switch self {
        case .small: NestSpace.s3 - NestSpace.s1
        case .medium: NestSpace.s4
        case .large: NestSpace.s5
        }
    }
}
