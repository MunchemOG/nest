import NestKit

/// Sizes on Home's grid, built from the spacing tokens.
enum HomeLayout {
    /// The width of the side column and the activity feed.
    static let column = NestSpace.s10 * 2 + NestSpace.s8 + NestSpace.s4
    /// The headline's widest line.
    static let headline = NestSpace.s10 * 6
}
