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
    /// Glass panels floating over the scene.
    public static let panel = NestShadow(layers: [
        Layer(inset: true, x: 0, y: 1, blur: 0, color: NestColor(rgba: 0xffffff0f)),
        Layer(x: 0, y: 1, blur: 2, color: NestColor(rgba: 0x0000004d)),
        Layer(x: 0, y: 24, blur: 48, spread: -20, color: NestColor(rgba: 0x000000bf)),
    ])
    /// The command bar: lit top edge, darker lower lip, deepest drop.
    public static let bar = NestShadow(layers: [
        Layer(inset: true, x: 0, y: 1, blur: 0, color: NestColor(rgba: 0xffffff12)),
        Layer(inset: true, x: 0, y: -1, blur: 0, color: NestColor(rgba: 0x00000059)),
        Layer(x: 0, y: 2, blur: 6, color: NestColor(rgba: 0x00000059)),
        Layer(x: 0, y: 28, blur: 60, spread: -24, color: NestColor(rgba: 0x000000d9)),
    ])
    /// Mini bird icons, so they read as small tiles.
    public static let icon = NestShadow(layers: [
        Layer(inset: true, x: 0, y: 1, blur: 0, color: NestColor(rgba: 0xffffff2e)),
        Layer(x: 0, y: 4, blur: 10, spread: -4, color: NestColor(rgba: 0x00000099)),
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

    /// Every shadow token, by its name in `tokens.json`.
    public static let all: [String: NestShadow] = [
        "shadow-rest": rest,
        "shadow-panel": panel,
        "shadow-bar": bar,
        "shadow-icon": icon,
        "shadow-popover": popover,
        "shadow-focus": focus,
    ]
}
