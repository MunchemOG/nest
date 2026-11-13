import NestKit
import SwiftUI

/// A bird as its app-icon tile, with a badge for what it is doing.
struct BirdAvatar: View {
    let bird: Bird
    let size: BirdAvatarSize
    let state: BirdAvatarState

    @Environment(\.accessibilityReduceMotion) private var systemReduceMotion
    @Environment(\.reduceMotionOverride) private var reduceMotionOverride

    init(_ bird: Bird, size: BirdAvatarSize = .small, state: BirdAvatarState = .resting) {
        self.bird = bird
        self.size = size
        self.state = state
    }

    /// What VoiceOver reads.
    var accessibilityText: String { "\(bird.name), \(state.word)" }

    var body: some View {
        let shape = RoundedRectangle(cornerRadius: size.cornerRadius, style: .continuous)
        Image(bird.glyph.tile)
            .resizable()
            .interpolation(.high)
            .frame(width: size.side, height: size.side)
            .clipShape(shape)
            .grayscale(state.isGrayscale ? 1 : 0)
            .nestShadow(.icon, in: shape)
            .overlay(alignment: .bottomTrailing) { badge.offset(x: size.badge / 4, y: size.badge / 4) }
            .animation(.nest(NestMotion.base), value: state)
            .accessibilityElement()
            .accessibilityLabel(accessibilityText)
    }

    @ViewBuilder private var badge: some View {
        switch state.badge {
        case .none:
            EmptyView()
        case .dot:
            Circle()
                .fill(Color(NestColor.surface0))
                .frame(width: size.badge, height: size.badge)
                .overlay {
                    StatusDot(
                        color: bird.color,
                        rest: bird.tint,
                        breathes: !(reduceMotionOverride ?? systemReduceMotion),
                        diameter: size.badge - NestSpace.s1
                    )
                }
        case .symbol(let name):
            Circle()
                .fill(Color(NestColor.surface2))
                .frame(width: size.badge, height: size.badge)
                .overlay {
                    Image(systemName: name)
                        .resizable()
                        .scaledToFit()
                        .padding(size.badge / 4)
                        .foregroundStyle(Color(NestColor.textSecondary))
                }
                .overlay { Circle().strokeBorder(Color(NestColor.surface0), lineWidth: NestSpace.s1 / 2) }
        }
    }
}
