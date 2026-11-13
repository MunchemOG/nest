import NestKit
import SwiftUI
import Testing
@testable import NestApp

@MainActor
struct NestButtonTests {
    @Test func primaryIsClayAndPressesDeeper() {
        #expect(NestButtonPalette(.primary, .rest).fill == .clay)
        #expect(NestButtonPalette(.primary, .rest).label == .onClay)
        #expect(NestButtonPalette(.primary, .pressed).fill == .clayDeep)
    }

    @Test func secondaryIsAnOutline() {
        let rest = NestButtonPalette(.secondary, .rest)
        #expect(rest.fill == nil)
        #expect(rest.border == .lineStrong)
        #expect(rest.label == .textPrimary)
        #expect(NestButtonPalette(.secondary, .hover).fill == .surface2)
    }

    @Test func quietHasNoEdgeUntilHovered() {
        #expect(NestButtonPalette(.quiet, .rest).fill == nil)
        #expect(NestButtonPalette(.quiet, .rest).border == nil)
        #expect(NestButtonPalette(.quiet, .rest).label == .textSecondary)
        #expect(NestButtonPalette(.quiet, .hover).label == .textPrimary)
    }

    @Test(arguments: NestButtonVariant.allCases)
    func disabledIsMutedWhateverElseIsTrue(_ variant: NestButtonVariant) {
        let state = NestButtonState(isEnabled: false, isHovered: true, isPressed: true, isFocused: true)
        #expect(NestButtonPalette(variant, state).label == .textMuted)
        #expect(state.showsFocusRing == false)
    }

    @Test(arguments: NestButtonVariant.allCases)
    func everyStateLooksDifferentFromRest(_ variant: NestButtonVariant) {
        let rest = NestButtonPalette(variant, .rest)
        for state in [NestButtonState.hover, .pressed, .disabled] {
            #expect(NestButtonPalette(variant, state) != rest, "\(variant) \(state)")
        }
        #expect(NestButtonState.focused.showsFocusRing)
    }

    @Test func sizesComeFromSpacingAndType() {
        #expect(NestButtonSize.small.height == NestFont.label.lineHeight + 2 * NestSpace.s1)
        #expect(NestButtonSize.regular.height == NestFont.label.lineHeight + 2 * NestSpace.s2)
        #expect(NestButtonSize.large.height == NestFont.body.lineHeight + 2 * NestSpace.s2)
        #expect(NestButtonSize.small.height < NestButtonSize.regular.height)
        #expect(NestButtonSize.regular.height < NestButtonSize.large.height)
    }

    static let states: [(String, NestButtonState)] = [
        ("rest", .rest), ("hover", .hover), ("pressed", .pressed), ("focused", .focused), ("disabled", .disabled),
    ]

    @Test(arguments: NestButtonVariant.allCases)
    func everyVariantAndStateMatchesItsSnapshot(_ variant: NestButtonVariant) throws {
        for (name, state) in Self.states {
            try Snapshot.expect(NestButtonFace("Build it", variant: variant, size: .regular, state: state), named: "button-\(variant)-\(name)")
        }
    }

    @Test(arguments: NestButtonSize.allCases)
    func everySizeMatchesItsSnapshot(_ size: NestButtonSize) throws {
        let row = HStack(spacing: NestSpace.s2) {
            ForEach(NestButtonVariant.allCases, id: \.self) { variant in
                NestButtonFace("Message", variant: variant, size: size, state: .rest)
            }
        }
        try Snapshot.expect(row, named: "button-size-\(size)")
    }

    @Test func theStyleWrapsARealButton() throws {
        let button = Button("Pause") {}.buttonStyle(NestButtonStyle(.secondary, size: .small))
        #expect(ImageRenderer(content: button).cgImage != nil)
    }
}
