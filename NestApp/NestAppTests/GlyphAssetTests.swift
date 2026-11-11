import AppKit
import Testing

struct GlyphAssetTests {
    static let glyphs = ["wren", "swift", "crow", "owl", "magpie", "peacock", "mark"]

    @Test(arguments: glyphs)
    func tileLoads(_ glyph: String) throws {
        let image = try #require(NSImage(named: "\(glyph)-tile"))
        #expect(image.isTemplate == false)
    }

    @Test(arguments: glyphs)
    func menuBarLoadsAsTemplate(_ glyph: String) throws {
        let image = try #require(NSImage(named: "\(glyph)-menubar"))
        #expect(image.isTemplate)
    }

    @Test func allFourteenLoad() {
        let names = Self.glyphs.flatMap { ["\($0)-tile", "\($0)-menubar"] }
        let loaded = names.compactMap { NSImage(named: $0) }
        #expect(names.count == 14)
        #expect(loaded.count == 14)
    }
}
