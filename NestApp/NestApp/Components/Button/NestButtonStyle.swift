import NestKit
import SwiftUI

/// The Nest's pill button: `Button("Pause") {}.buttonStyle(NestButtonStyle(.secondary))`.
struct NestButtonStyle: ButtonStyle {
    let variant: NestButtonVariant
    let size: NestButtonSize

    init(_ variant: NestButtonVariant = .secondary, size: NestButtonSize = .regular) {
        self.variant = variant
        self.size = size
    }

    func makeBody(configuration: Configuration) -> some View {
        LiveFace(configuration: configuration, variant: variant, size: size)
    }

    private struct LiveFace: View {
        let configuration: Configuration
        let variant: NestButtonVariant
        let size: NestButtonSize

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
            NestButtonFace(variant: variant, size: size, state: state) { configuration.label }
                .onHover { isHovered = $0 }
                .animation(.nest(configuration.isPressed ? NestMotion.instant : NestMotion.fast), value: state)
                .focusEffectDisabled()
        }
    }
}
