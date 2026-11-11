import AppKit
import NestKit
import Testing

struct BirdGlyphTests {
    @Test(arguments: Bird.allCases)
    func tileGlyphResolvesToAnImage(_ bird: Bird) throws {
        let image = try #require(NSImage(named: bird.glyph.tile), "\(bird.name) has no tile image")
        #expect(image.isTemplate == false)
    }

    @Test(arguments: Bird.allCases)
    func menuBarGlyphResolvesToATemplateImage(_ bird: Bird) throws {
        let image = try #require(NSImage(named: bird.glyph.menuBar), "\(bird.name) has no menu bar image")
        #expect(image.isTemplate)
    }
}
