/// Corner radius tokens from `design/tokens.json`, in points.
public enum NestRadius {
    /// Mini bird icons, key caps, small chips.
    public static let sm: Double = 8
    /// Rail buttons, list rows on hover, menu items.
    public static let md: Double = 12
    /// Cards inside a panel.
    public static let lg: Double = 14
    /// Glass panels and sheets.
    public static let xl: Double = 20
    /// A bird tile at 100 points; scale with the tile.
    public static let tile: Double = 24
    /// Pills and circles.
    public static let full: Double = 9999

    /// Every radius token, by its name in `tokens.json`.
    public static let all: [String: Double] = [
        "radius-sm": sm,
        "radius-md": md,
        "radius-lg": lg,
        "radius-xl": xl,
        "radius-tile": tile,
        "radius-full": full,
    ]
}
