/// A shadow token from `design/tokens.json`: one or more layers, drawn in order.
public struct NestShadow: Hashable, Sendable {
    /// One layer of a shadow, measured in points.
    public struct Layer: Hashable, Sendable {
        /// Whether the layer is drawn inside the shape's edge.
        public let inset: Bool
        /// Horizontal offset.
        public let x: Double
        /// Vertical offset.
        public let y: Double
        /// Blur radius.
        public let blur: Double
        /// How far the shadow grows past the shape before blurring.
        public let spread: Double
        /// The shadow's colour.
        public let color: NestColor

        /// A layer from its parts.
        public init(inset: Bool = false, x: Double, y: Double, blur: Double, spread: Double = 0, color: NestColor) {
            self.inset = inset
            self.x = x
            self.y = y
            self.blur = blur
            self.spread = spread
            self.color = color
        }
    }

    /// The layers, in the order they are drawn.
    public let layers: [Layer]

    /// A shadow from its layers.
    public init(layers: [Layer]) {
        self.layers = layers
    }

    /// Cards at rest: a thin lit top edge and a soft deep drop.
    public static let rest = NestShadow(layers: [
        Layer(inset: true, x: 0, y: 1, blur: 0, color: NestColor(rgba: 0xffffff0d)),
        Layer(x: 0, y: 1, blur: 2, color: NestColor(rgba: 0x00000066)),
        Layer(x: 0, y: 8, blur: 24, color: NestColor(rgba: 0x00000059)),
    ])
    /// Hovered or selected cards: a warm clay glow.
    public static let glow = NestShadow(layers: [
        Layer(inset: true, x: 0, y: 1, blur: 0, color: NestColor(rgba: 0xffffff14)),
        Layer(x: 0, y: 0, blur: 0, spread: 0.5, color: NestColor(rgba: 0xcb6d4d66)),
        Layer(x: 0, y: 16, blur: 48, color: NestColor(rgba: 0xcb6d4d2e)),
    ])
    /// Floating panels on glass.
    public static let popover = NestShadow(layers: [
        Layer(inset: true, x: 0, y: 1, blur: 0, color: NestColor(rgba: 0xffffff14)),
        Layer(x: 0, y: 12, blur: 40, color: NestColor(rgba: 0x000000a6)),
    ])
    /// Keyboard focus: a clay ring offset from the element, with a soft glow.
    public static let focus = NestShadow(layers: [
        Layer(x: 0, y: 0, blur: 0, spread: 2, color: NestColor(rgb: 0x0c0c0d)),
        Layer(x: 0, y: 0, blur: 0, spread: 4, color: NestColor(rgb: 0xcb6d4d)),
        Layer(x: 0, y: 0, blur: 20, color: NestColor(rgba: 0xcb6d4d59)),
    ])
    /// Wren's avatar while it is active or speaking.
    public static let glowWren = birdGlow(NestColor(rgba: 0xd2ae8a66))
    /// Swift's avatar while it is active or speaking.
    public static let glowSwift = birdGlow(NestColor(rgba: 0x6e9bd366))
    /// Crow's avatar while it is active or speaking.
    public static let glowCrow = birdGlow(NestColor(rgba: 0x8e86d666))
    /// Owl's avatar while it is active or speaking.
    public static let glowOwl = birdGlow(NestColor(rgba: 0xd4a95466))
    /// Magpie's avatar while it is active or speaking.
    public static let glowMagpie = birdGlow(NestColor(rgba: 0xd47a9366))
    /// Peacock's avatar while it is active or speaking.
    public static let glowPeacock = birdGlow(NestColor(rgba: 0xc27bb866))

    /// Every shadow token, by its name in `tokens.json`.
    public static let all: [String: NestShadow] = [
        "shadow-rest": rest,
        "shadow-glow": glow,
        "shadow-popover": popover,
        "shadow-focus": focus,
        "glow-wren": glowWren,
        "glow-swift": glowSwift,
        "glow-crow": glowCrow,
        "glow-owl": glowOwl,
        "glow-magpie": glowMagpie,
        "glow-peacock": glowPeacock,
    ]

    private static func birdGlow(_ color: NestColor) -> NestShadow {
        NestShadow(layers: [
            Layer(x: 0, y: 0, blur: 0, spread: 2, color: NestColor(rgb: 0x0c0c0d)),
            Layer(x: 0, y: 0, blur: 16, color: color),
        ])
    }
}
