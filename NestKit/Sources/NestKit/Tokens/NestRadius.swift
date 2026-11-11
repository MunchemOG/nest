/// Corner radius tokens from `design/tokens.json`, in points.
public enum NestRadius {
    /// Tags, status pills, small chips.
    public static let sm: Double = 4
    /// Buttons, inputs, menu items, thumbnails.
    public static let md: Double = 6
    /// Cards, chat bubbles, popovers, media frames.
    public static let lg: Double = 10
    /// Windows, sheets and large panels.
    public static let xl: Double = 14
    /// Circles only: bird avatars, status dots, toggles.
    public static let full: Double = 9999

    /// Every radius token, by its name in `tokens.json`.
    public static let all: [String: Double] = [
        "radius-sm": sm,
        "radius-md": md,
        "radius-lg": lg,
        "radius-xl": xl,
        "radius-full": full,
    ]
}
