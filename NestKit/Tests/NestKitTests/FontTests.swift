import CoreText
import Foundation
import Testing
@testable import NestKit

struct FontTests {
    /// The first quoted name in a CSS font stack, e.g. `Inter Tight` from `"Inter Tight", ui-sans-serif`.
    static func firstFamily(_ stack: String) throws -> String {
        let parts = stack.split(separator: "\"", omittingEmptySubsequences: false)
        return try #require(parts.count > 2 ? String(parts[1]) : nil, "no quoted family in \(stack)")
    }

    static func registeredFamilies() -> Set<String> {
        Set(CTFontManagerCopyAvailableFontFamilyNames() as? [String] ?? [])
    }

    @Test func everyFamilyInTokensIsRegistered() throws {
        try NestFont.registerBundledFonts()
        let families = Self.registeredFamilies()
        for stack in try TokenFile.load().type.families.values {
            let family = try Self.firstFamily(stack)
            #expect(families.contains(family), "\(family) is not registered")
        }
    }

    @Test func everyFamilyHasAnEqualSwiftValue() throws {
        let stacks = try TokenFile.load().type.families
        #expect(Set(NestFont.Family.allCases.map(\.rawValue)) == Set(stacks.keys))
        for family in NestFont.Family.allCases {
            #expect(family.name == (try Self.firstFamily(try #require(stacks[family.rawValue]))), "\(family)")
        }
    }

    @Test func registeringTwiceIsHarmless() throws {
        try NestFont.registerBundledFonts()
        try NestFont.registerBundledFonts()
    }

    @Test func everyTextStyleHasAnEqualSwiftValue() throws {
        let groups = try TokenFile.load().type.groups
        let styles = groups.flatMap { group in group.styles.map { (group.family, $0) } }
        #expect(NestFont.styles.map(\.name) == styles.map(\.1.name))
        #expect(Set(NestFont.all.keys) == Set(styles.map(\.1.name)))
        for (family, style) in styles {
            let swift = try #require(NestFont.all[style.name], "\(style.name) has no Swift value")
            #expect(swift.family.rawValue == family, "\(style.name)")
            #expect(swift.size == (try CSSValue.length(style.fontSize)), "\(style.name)")
            #expect(swift.lineHeight == (try CSSValue.length(style.lineHeight)), "\(style.name)")
            #expect(swift.weight == style.fontWeight, "\(style.name)")
            #expect(swift.letterSpacing == (try style.letterSpacing.map(CSSValue.em) ?? 0), "\(style.name)")
            #expect(swift.sample == style.sample, "\(style.name)")
        }
    }

    @Test(arguments: NestFont.styles)
    func everyStyleResolvesToItsOwnFace(_ style: NestFont) throws {
        try NestFont.registerBundledFonts()
        let font = CTFontCreateWithName(style.postScriptName as CFString, style.size, nil)
        #expect(CTFontCopyFamilyName(font) as String == style.family.name, "\(style.name)")
        let traits = CTFontCopyTraits(font) as? [String: Any] ?? [:]
        let weight = try #require(traits[kCTFontWeightTrait as String] as? Double)
        #expect(abs(weight - style.coreTextWeight) < 0.01, "\(style.name) weight \(weight)")
    }

    @Test func trackingIsLetterSpacingTimesSize() {
        #expect(NestFont.displayXL.tracking == -0.045 * 104)
        #expect(NestFont.bodyS.tracking == 0)
    }
}

struct BundledFontFileTests {
    @Test func everyFontFileIsListed() {
        let names = Set(NestFont.bundledFontURLs.map(\.lastPathComponent))
        #expect(names == ["InterTight.ttf", "Inter.ttf", "IBMPlexMono-Regular.ttf"])
    }
}
