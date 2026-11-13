import NestKit

/// Sizes on Home's grid, built from the spacing tokens.
enum HomeLayout {
    /// The width of the side column and the activity feed.
    static let column = NestSpace.s10 * 2 + NestSpace.s8 + NestSpace.s4
    /// Space left of the content for the rail, and right of it before the window's edge.
    static let leadingInset = NestSpace.s9 + NestSpace.s4
    static let trailingInset = NestSpace.s6
    /// How far right of the window's centre the command bar sits, clearing the rail (as in the prototype).
    static let dockShift = NestSpace.s8
    /// The command bar's widest.
    static let dockWidth = NestSpace.s10 * 5

    /// The command bar's centre and width in a content area `width` wide: centred on the window,
    /// and narrowed if needed so it never reaches the activity panel on the left.
    static func dock(inContentWidth width: Double) -> (centre: Double, width: Double) {
        let window = width + leadingInset + trailingInset
        let centre = window / 2 + dockShift - leadingInset
        let room = 2 * (centre - column - NestSpace.s4)
        return (centre, max(0, min(dockWidth, room, width)))
    }

    /// The headline's widest line.
    static let headline = NestSpace.s10 * 6
}
