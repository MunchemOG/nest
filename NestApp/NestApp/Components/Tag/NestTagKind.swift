import NestKit

/// What a tag marks, which sets its colours.
enum NestTagKind: Hashable, Sendable {
    /// Plain metadata.
    case neutral
    /// Something you can act on; follows the accent.
    case clay
    /// A secondary highlight.
    case sage
    /// A secondary highlight.
    case lagoon
    /// Something that belongs to one bird; drawn only in that bird's colours.
    case bird(Bird)

    nonisolated static let allCases: [NestTagKind] = [.neutral, .clay, .sage, .lagoon] + Bird.allCases.map { .bird($0) }

    /// A short name for tests and snapshots.
    var name: String {
        switch self {
        case .neutral: "neutral"
        case .clay: "clay"
        case .sage: "sage"
        case .lagoon: "lagoon"
        case .bird(let bird): bird.rawValue
        }
    }

    /// The tag's background.
    var fill: NestColor {
        switch self {
        case .neutral: .surface2
        case .clay: .clayTint
        case .sage: .sageTint
        case .lagoon: .lagoonTint
        case .bird(let bird): bird.tint
        }
    }

    /// The tag's text.
    var label: NestColor {
        switch self {
        case .neutral: .textSecondary
        case .clay: .claySoft
        case .sage: .sageSoft
        case .lagoon: .lagoonSoft
        case .bird(let bird): bird.color
        }
    }

    /// The edge drawn around a selected tag; none at rest.
    func border(selected: Bool) -> NestColor? {
        guard selected else { return nil }
        return self == .neutral ? .lineStrong : label
    }
}
