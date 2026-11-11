/// The asset names of one glyph from `design/glyphs/`, in its two forms.
public struct Glyph: Hashable, Sendable {
    /// The full-colour image for tiles and avatars.
    public let tile: String
    /// The template image for the menu bar.
    public let menuBar: String

    /// The glyph whose assets are named `<base>-tile` and `<base>-menubar`.
    public init(base: String) {
        tile = "\(base)-tile"
        menuBar = "\(base)-menubar"
    }
}
