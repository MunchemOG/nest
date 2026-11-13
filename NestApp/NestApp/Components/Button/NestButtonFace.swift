import NestKit
import SwiftUI

/// How a button looks in one state. `NestButtonStyle` feeds it the live state.
struct NestButtonFace<Label: View>: View {
    let label: Label
    let variant: NestButtonVariant
    let size: NestButtonSize
    let state: NestButtonState

    @Environment(\.pixelLength) private var hairline

    init(variant: NestButtonVariant, size: NestButtonSize, state: NestButtonState, @ViewBuilder label: () -> Label) {
        self.label = label()
        self.variant = variant
        self.size = size
        self.state = state
    }

    var body: some View {
        let palette = NestButtonPalette(variant, state)
        label
            .nestFont(size.font)
            .lineLimit(1)
            .foregroundStyle(Color(palette.label))
            .padding(.horizontal, size.horizontalPadding)
            .frame(height: size.height)
            .background { Capsule().fill(palette.fill.map { Color($0) } ?? .clear) }
            .overlay { Capsule().strokeBorder(palette.border.map { Color($0) } ?? .clear, lineWidth: hairline) }
            .nestFocusRing(state.showsFocusRing, in: Capsule())
            .contentShape(Capsule())
    }
}

extension NestButtonFace where Label == Text {
    /// A face with a plain text label.
    init(_ title: String, variant: NestButtonVariant, size: NestButtonSize, state: NestButtonState) {
        self.init(variant: variant, size: size, state: state) { Text(title) }
    }
}
