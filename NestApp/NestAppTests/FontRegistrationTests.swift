import AppKit
import NestKit
import Testing

struct FontRegistrationTests {
    @Test func theAppRegistersEveryFamilyAtLaunch() {
        let families = Set(NSFontManager.shared.availableFontFamilies)
        for family in NestFont.Family.allCases {
            #expect(families.contains(family.name), "\(family.name) is not registered")
        }
    }

    @Test(arguments: NestFont.styles)
    func everyStyleOpensInTheApp(_ style: NestFont) throws {
        let font = try #require(NSFont(name: style.postScriptName, size: style.size), "\(style.name)")
        #expect(font.familyName == style.family.name)
    }
}
