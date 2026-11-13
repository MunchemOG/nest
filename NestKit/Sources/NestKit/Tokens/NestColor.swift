/// A colour token from `design/tokens.json`, as 8-bit sRGB channels.
public struct NestColor: Hashable, Sendable {
    /// Red, 0 to 255.
    public let red: UInt8
    /// Green, 0 to 255.
    public let green: UInt8
    /// Blue, 0 to 255.
    public let blue: UInt8
    /// Opacity, 0 (clear) to 255 (solid).
    public let alpha: UInt8

    /// A colour from its four channels.
    public init(red: UInt8, green: UInt8, blue: UInt8, alpha: UInt8) {
        self.red = red
        self.green = green
        self.blue = blue
        self.alpha = alpha
    }

    /// A solid colour written as `0xrrggbb`.
    public init(rgb: UInt32) {
        self.init(rgba: rgb << 8 | 0xff)
    }

    /// A colour written as `0xrrggbbaa`.
    public init(rgba: UInt32) {
        self.init(
            red: UInt8(truncatingIfNeeded: rgba >> 24),
            green: UInt8(truncatingIfNeeded: rgba >> 16),
            blue: UInt8(truncatingIfNeeded: rgba >> 8),
            alpha: UInt8(truncatingIfNeeded: rgba)
        )
    }

    /// Page background behind any 2D view.
    public static let surface0 = NestColor(rgb: 0x0c0c0d)
    /// Cards and sections on `surface0`.
    public static let surface1 = NestColor(rgb: 0x141416)
    /// Raised panels, hovered cards, inputs.
    public static let surface2 = NestColor(rgb: 0x1c1c1f)
    /// Popovers, menus, the highest layer.
    public static let surface3 = NestColor(rgb: 0x26262a)
    /// Hairline borders and dividers.
    public static let line = NestColor(rgba: 0xffffff14)
    /// Emphasized borders and the hover state of `line`.
    public static let lineStrong = NestColor(rgba: 0xffffff24)
    /// Headings and body text.
    public static let textPrimary = NestColor(rgb: 0xecebe8)
    /// Supporting text and descriptions.
    public static let textSecondary = NestColor(rgb: 0xa3a29e)
    /// Metadata, dates, captions and placeholders.
    public static let textMuted = NestColor(rgb: 0x8a8984)
    /// The primary accent: the thing you can press.
    public static let clay = NestColor(rgb: 0xcb6d4d)
    /// Pressed clay fills; large decorative blocks.
    public static let clayDeep = NestColor(rgb: 0x8f4530)
    /// Clay text on `clayTint`; highlights.
    public static let claySoft = NestColor(rgb: 0xe8a88f)
    /// Translucent background behind `claySoft` text.
    public static let clayTint = NestColor(rgba: 0xcb6d4d24)
    /// Text and icons on a clay fill.
    public static let onClay = NestColor(rgb: 0x0c0c0d)
    /// Secondary colour for tags, highlights and illustration.
    public static let sage = NestColor(rgb: 0x819f60)
    /// Decorative blocks and pressed states for sage.
    public static let sageDeep = NestColor(rgb: 0x56703c)
    /// Sage text on `sageTint`.
    public static let sageSoft = NestColor(rgb: 0xb5cc9a)
    /// Translucent background behind `sageSoft` text.
    public static let sageTint = NestColor(rgba: 0x819f6024)
    /// Secondary colour for tags, highlights and illustration.
    public static let lagoon = NestColor(rgb: 0x53ac95)
    /// Decorative blocks and pressed states for lagoon.
    public static let lagoonDeep = NestColor(rgb: 0x33765f)
    /// Lagoon text on `lagoonTint`.
    public static let lagoonSoft = NestColor(rgb: 0x95d1c1)
    /// Translucent background behind `lagoonSoft` text.
    public static let lagoonTint = NestColor(rgba: 0x53ac9524)
    /// Keyboard focus ring; follows `clay`.
    public static let focus = clay
    /// Shipped, passed, done.
    public static let statusSuccess = NestColor(rgb: 0x6fc28b)
    /// Needs a look, degraded.
    public static let statusWarning = NestColor(rgb: 0xe7b04b)
    /// Failed, error, destructive.
    public static let statusDanger = NestColor(rgb: 0xe8645a)
    /// Wren's colour (sand).
    public static let flockWren = NestColor(rgb: 0xd2ae8a)
    /// Swift's colour (sky).
    public static let flockSwift = NestColor(rgb: 0x6e9bd3)
    /// Crow's colour (iris).
    public static let flockCrow = NestColor(rgb: 0x8e86d6)
    /// Owl's colour (ember).
    public static let flockOwl = NestColor(rgb: 0xd4a954)
    /// Magpie's colour (rose).
    public static let flockMagpie = NestColor(rgb: 0xd47a93)
    /// Peacock's colour (orchid).
    public static let flockPeacock = NestColor(rgb: 0xc27bb8)
    /// A 14% wash of Wren's colour.
    public static let flockWrenTint = NestColor(rgba: 0xd2ae8a24)
    /// A 14% wash of Swift's colour.
    public static let flockSwiftTint = NestColor(rgba: 0x6e9bd324)
    /// A 14% wash of Crow's colour.
    public static let flockCrowTint = NestColor(rgba: 0x8e86d624)
    /// A 14% wash of Owl's colour.
    public static let flockOwlTint = NestColor(rgba: 0xd4a95424)
    /// A 14% wash of Magpie's colour.
    public static let flockMagpieTint = NestColor(rgba: 0xd47a9324)
    /// A 14% wash of Peacock's colour.
    public static let flockPeacockTint = NestColor(rgba: 0xc27bb824)
    /// Smoked glass for every floating panel over the scene.
    public static let glass = NestColor(rgba: 0x16161b8f)
    /// The command bar's slightly lighter glass.
    public static let glassBar = NestColor(rgba: 0x1e1e2399)
    /// The glyph on a bird tile.
    public static let glyphInk = NestColor(rgb: 0x0c0c0d)
    /// The dark of the 3D studio behind the flock.
    public static let sceneVoid = NestColor(rgb: 0x09090b)
    /// The lacquered studio floor.
    public static let sceneFloor = NestColor(rgb: 0x0b0b0d)
    /// Wall light tint in Morning mode.
    public static let modeMorning = NestColor(rgb: 0xc88a5c)
    /// Wall light tint in Focus mode.
    public static let modeFocus = NestColor(rgb: 0x5a64c8)
    /// Wall light tint in Night mode.
    public static let modeNight = NestColor(rgb: 0x3a5aa8)

    /// Every colour token, by its name in `tokens.json`.
    public static let all: [String: NestColor] = [
        "surface-0": surface0,
        "surface-1": surface1,
        "surface-2": surface2,
        "surface-3": surface3,
        "line": line,
        "line-strong": lineStrong,
        "text-primary": textPrimary,
        "text-secondary": textSecondary,
        "text-muted": textMuted,
        "clay": clay,
        "clay-deep": clayDeep,
        "clay-soft": claySoft,
        "clay-tint": clayTint,
        "on-clay": onClay,
        "sage": sage,
        "sage-deep": sageDeep,
        "sage-soft": sageSoft,
        "sage-tint": sageTint,
        "lagoon": lagoon,
        "lagoon-deep": lagoonDeep,
        "lagoon-soft": lagoonSoft,
        "lagoon-tint": lagoonTint,
        "focus": focus,
        "status-success": statusSuccess,
        "status-warning": statusWarning,
        "status-danger": statusDanger,
        "flock-wren": flockWren,
        "flock-swift": flockSwift,
        "flock-crow": flockCrow,
        "flock-owl": flockOwl,
        "flock-magpie": flockMagpie,
        "flock-peacock": flockPeacock,
        "flock-wren-tint": flockWrenTint,
        "flock-swift-tint": flockSwiftTint,
        "flock-crow-tint": flockCrowTint,
        "flock-owl-tint": flockOwlTint,
        "flock-magpie-tint": flockMagpieTint,
        "flock-peacock-tint": flockPeacockTint,
        "glass": glass,
        "glass-bar": glassBar,
        "glyph-ink": glyphInk,
        "scene-void": sceneVoid,
        "scene-floor": sceneFloor,
        "mode-morning": modeMorning,
        "mode-focus": modeFocus,
        "mode-night": modeNight,
    ]
}
