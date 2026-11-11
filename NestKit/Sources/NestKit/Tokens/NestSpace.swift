/// Spacing tokens from `design/tokens.json`, in points, on a 4-point grid.
public enum NestSpace {
    /// 4: icon-to-label gaps, tight inline spacing.
    public static let s1: Double = 4
    /// 8: gaps inside a component.
    public static let s2: Double = 8
    /// 12: small stacks.
    public static let s3: Double = 12
    /// 16: grid gap between cards; stacks inside a card.
    public static let s4: Double = 16
    /// 24: card padding.
    public static let s5: Double = 24
    /// 32: section heading to its content.
    public static let s6: Double = 32
    /// 48: between subsections on a page.
    public static let s7: Double = 48
    /// 64: page side margin.
    public static let s8: Double = 64
    /// 96: between page sections.
    public static let s9: Double = 96
    /// 128: top of the hero; the biggest gaps.
    public static let s10: Double = 128

    /// Every spacing token, by its name in `tokens.json`.
    public static let all: [String: Double] = [
        "space-1": s1,
        "space-2": s2,
        "space-3": s3,
        "space-4": s4,
        "space-5": s5,
        "space-6": s6,
        "space-7": s7,
        "space-8": s8,
        "space-9": s9,
        "space-10": s10,
    ]
}
