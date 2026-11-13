import Testing
@testable import NestKit

struct TokenTests {
    /// Top-level groups of `tokens.json` that are not turned into Swift values.
    static let groupsNotInSwift: Set<String> = ["name", "version"]
    static let groupsInSwift: Set<String> = ["color", "spacing", "radius", "shadow", "duration", "easing", "type", "effect"]

    @Test func everyTokenGroupIsCoveredOrKnowinglyLeftOut() throws {
        #expect(try TokenFile.topLevelKeys() == Self.groupsInSwift.union(Self.groupsNotInSwift))
    }

    @Test func everyColourTokenHasAnEqualSwiftValue() throws {
        let tokens = try TokenFile.load().color.tokens
        let byName = Dictionary(uniqueKeysWithValues: tokens.map { ($0.name, $0.value) })
        #expect(Set(NestColor.all.keys) == Set(byName.keys))
        for token in tokens {
            var value = token.value
            if value.hasPrefix("{"), value.hasSuffix("}") {
                value = try #require(byName[String(value.dropFirst().dropLast())], "\(token.name) refers to a missing token")
            }
            #expect(NestColor.all[token.name] == (try CSSValue.color(value)), "\(token.name)")
        }
    }

    @Test func focusFollowsClay() {
        #expect(NestColor.focus == NestColor.clay)
    }

    @Test func everySpacingTokenHasAnEqualSwiftValue() throws {
        let tokens = try TokenFile.load().spacing.tokens
        #expect(Set(NestSpace.all.keys) == Set(tokens.map(\.name)))
        for token in tokens {
            #expect(NestSpace.all[token.name] == (try CSSValue.length(token.value)), "\(token.name)")
        }
    }

    @Test func everyRadiusTokenHasAnEqualSwiftValue() throws {
        let tokens = try TokenFile.load().radius.tokens
        #expect(Set(NestRadius.all.keys) == Set(tokens.map(\.name)))
        for token in tokens {
            #expect(NestRadius.all[token.name] == (try CSSValue.length(token.value)), "\(token.name)")
        }
    }

    @Test func everyShadowTokenHasAnEqualSwiftValue() throws {
        let tokens = try TokenFile.load().shadow.tokens
        #expect(Set(NestShadow.all.keys) == Set(tokens.map(\.name)))
        for token in tokens {
            #expect(NestShadow.all[token.name] == (try CSSValue.shadow(token.value)), "\(token.name)")
        }
    }

    @Test func everyDurationTokenHasAnEqualSwiftValue() throws {
        let tokens = try TokenFile.load().duration.tokens
        #expect(Set(NestMotion.durations.keys) == Set(tokens.map(\.name)))
        for token in tokens {
            #expect(NestMotion.durations[token.name] == (try CSSValue.duration(token.value)), "\(token.name)")
        }
    }

    @Test func everyEasingTokenHasAnEqualSwiftValue() throws {
        let tokens = try TokenFile.load().easing.tokens
        #expect(Set(NestMotion.curves.keys) == Set(tokens.map(\.name)))
        for token in tokens {
            #expect(NestMotion.curves[token.name] == (try CSSValue.curve(token.value)), "\(token.name)")
        }
    }

    @Test func everyEffectTokenHasAnEqualSwiftValue() throws {
        let tokens = try TokenFile.load().effect.tokens
        let byName = Dictionary(uniqueKeysWithValues: tokens.map { ($0.name, $0.value) })
        #expect(Set(byName.keys) == ["blur-glass", "lift-hover"])
        #expect(NestEffect.blurGlass == (try CSSValue.blur(try #require(byName["blur-glass"]))))
        #expect(NestEffect.liftHover == (try CSSValue.length(try #require(byName["lift-hover"]))))
    }

    @Test func hexColoursSplitIntoChannels() {
        #expect(NestColor(rgb: 0xcb6d4d) == NestColor(red: 0xcb, green: 0x6d, blue: 0x4d, alpha: 0xff))
        #expect(NestColor(rgba: 0xcb6d4d24) == NestColor(red: 0xcb, green: 0x6d, blue: 0x4d, alpha: 0x24))
    }
}
