import NestKit
import SwiftUI

/// How a card looks in one state. A bird's card carries a wash of its tint in the top corner.
struct NestCardFace<Content: View>: View {
    let bird: Bird?
    let state: NestCardState
    let content: Content

    @Environment(\.pixelLength) private var hairline
    @Environment(\.nestAccent) private var accent

    init(bird: Bird? = nil, state: NestCardState = .rest, @ViewBuilder content: () -> Content) {
        self.bird = bird
        self.state = state
        self.content = content()
    }

    /// The corner wash colour, if the card belongs to a bird.
    var wash: NestColor? { bird?.tint }

    var body: some View {
        let shape = RoundedRectangle(cornerRadius: NestRadius.lg, style: .continuous)
        let palette = NestCardPalette(state, accent: accent)
        content
            .padding(NestSpace.s5)
            .background {
                shape.fill(Color(palette.fill))
                    .overlay {
                        if let wash {
                            shape.fill(RadialGradient(
                                colors: [Color(wash), .clear],
                                center: .topLeading,
                                startRadius: 0,
                                endRadius: NestSpace.s10
                            ))
                        }
                    }
            }
            .overlay { shape.strokeBorder(Color(palette.border), lineWidth: hairline) }
            .nestShadow(.rest, in: shape)
            .nestFocusRing(state.isFocused, in: shape)
            .contentShape(shape)
    }
}
