import NestKit
import SwiftUI

/// A round primary button sized to sit inside the composer.
struct SendButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        LiveFace(configuration: configuration)
    }

    private struct LiveFace: View {
        let configuration: Configuration

        @Environment(\.isEnabled) private var isEnabled
        @Environment(\.isFocused) private var isFocused
        @State private var isHovered = false

        var body: some View {
            let state = NestButtonState(
                isEnabled: isEnabled,
                isHovered: isHovered,
                isPressed: configuration.isPressed,
                isFocused: isFocused
            )
            let palette = NestButtonPalette(.primary, state)
            let side = NestButtonSize.regular.height
            configuration.label
                .foregroundStyle(Color(palette.label))
                .frame(width: side, height: side)
                .background { Circle().fill(palette.fill.map { Color($0) } ?? .clear) }
                .nestFocusRing(state.showsFocusRing, in: Circle())
                .contentShape(Circle())
                .onHover { isHovered = $0 }
                .animation(.nest(configuration.isPressed ? NestMotion.instant : NestMotion.fast), value: state)
                .focusEffectDisabled()
        }
    }
}
