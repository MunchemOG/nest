/// The colour of a project's tile, from the Nest's accents (never a bird's colour).
public enum ProjectTile: String, Sendable, Equatable, CaseIterable, Codable {
    /// Clay.
    case clay
    /// Sage.
    case sage
    /// Lagoon.
    case lagoon

    /// The tile's colour.
    public var color: NestColor {
        switch self {
        case .clay: .clay
        case .sage: .sage
        case .lagoon: .lagoon
        }
    }

    /// The tile's lighter top edge.
    public var light: NestColor {
        switch self {
        case .clay: .claySoft
        case .sage: .sageSoft
        case .lagoon: .lagoonSoft
        }
    }
}
