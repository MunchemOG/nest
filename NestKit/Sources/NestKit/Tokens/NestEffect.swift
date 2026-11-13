/// Effect tokens from `design/tokens.json`.
public enum NestEffect {
    /// A backdrop blur: a radius in points and a saturation multiplier.
    public struct Blur: Hashable, Sendable {
        /// Blur radius.
        public let radius: Double
        /// How much the colours behind are saturated; 1 leaves them alone.
        public let saturation: Double

        /// A blur from its parts.
        public init(radius: Double, saturation: Double) {
            self.radius = radius
            self.saturation = saturation
        }
    }

    /// The backdrop of every glass panel, over the `glass` or `glass-bar` fill.
    public static let blurGlass = Blur(radius: 26, saturation: 1.6)
    /// How far a hovered tile or focused command bar rises, in points (negative is up).
    public static let liftHover: Double = -2
}
