/// Duration and easing tokens from `design/tokens.json`.
public enum NestMotion {
    /// A cubic Bézier timing curve from (0, 0) to (1, 1) through two control points.
    public struct Curve: Hashable, Sendable {
        /// First control point, x.
        public let x1: Double
        /// First control point, y.
        public let y1: Double
        /// Second control point, x.
        public let x2: Double
        /// Second control point, y.
        public let y2: Double

        /// A curve from its two control points.
        public init(x1: Double, y1: Double, x2: Double, y2: Double) {
            self.x1 = x1
            self.y1 = y1
            self.x2 = x2
            self.y2 = y2
        }
    }

    /// Press feedback.
    public static let instant = Duration.milliseconds(80)
    /// Hover and focus colour changes.
    public static let fast = Duration.milliseconds(140)
    /// A card rising, a pill changing state, a message arriving.
    public static let base = Duration.milliseconds(250)
    /// Panels entering; the longest anything a person waits on may take.
    public static let slow = Duration.milliseconds(420)
    /// Ambient only: an active bird's glow breathing.
    public static let breathe = Duration.milliseconds(2400)

    /// The default: starts fast, lands softly.
    public static let easeOut = Curve(x1: 0.22, y1: 1, x2: 0.36, y2: 1)
    /// Moving from one place to another; the breathing glow.
    public static let easeInOut = Curve(x1: 0.65, y1: 0, x2: 0.35, y2: 1)
    /// A small overshoot, for Wren's menu bar hop only.
    public static let easeHop = Curve(x1: 0.34, y1: 1.4, x2: 0.64, y2: 1)

    /// Every duration token, by its name in `tokens.json`.
    public static let durations: [String: Duration] = [
        "duration-instant": instant,
        "duration-fast": fast,
        "duration-base": base,
        "duration-slow": slow,
        "duration-breathe": breathe,
    ]

    /// Every easing token, by its name in `tokens.json`.
    public static let curves: [String: Curve] = [
        "ease-out": easeOut,
        "ease-in-out": easeInOut,
        "ease-hop": easeHop,
    ]
}
