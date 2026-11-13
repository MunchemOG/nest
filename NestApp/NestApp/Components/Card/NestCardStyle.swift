import NestKit
import SwiftUI

/// Makes a button look like a card: `Button { … } label: { … }.buttonStyle(NestCardStyle(isSelected: true))`.
struct NestCardStyle: ButtonStyle {
    let bird: Bird?
    let isSelected: Bool

    init(bird: Bird? = nil, isSelected: Bool = false) {
        self.bird = bird
        self.isSelected = isSelected
    }

    func makeBody(configuration: Configuration) -> some View {
        LiveFace(configuration: configuration, bird: bird, isSelected: isSelected)
    }

    private struct LiveFace: View {
        let configuration: Configuration
        let bird: Bird?
        let isSelected: Bool

        @Environment(\.isFocused) private var isFocused
        @State private var isHovered = false

        var body: some View {
            let state = NestCardState(
                isHovered: isHovered,
                isPressed: configuration.isPressed,
                isSelected: isSelected,
                isFocused: isFocused
            )
            NestCardFace(bird: bird, state: state) { configuration.label }
                .onHover { isHovered = $0 }
                .animation(.nest(configuration.isPressed ? NestMotion.instant : NestMotion.fast), value: state)
                .focusEffectDisabled()
                .accessibilityAddTraits(isSelected ? .isSelected : [])
        }
    }
}
