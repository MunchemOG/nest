/// A point on the screen, in points, for the pets.
public struct PetPoint: Hashable, Sendable, Codable {
    /// Horizontal position.
    public var x: Double
    /// Vertical position.
    public var y: Double

    /// A point from its two coordinates.
    public init(x: Double, y: Double) {
        self.x = x
        self.y = y
    }

    /// The straight-line distance to `other`.
    public func distance(to other: PetPoint) -> Double {
        ((x - other.x) * (x - other.x) + (y - other.y) * (y - other.y)).squareRoot()
    }
}
