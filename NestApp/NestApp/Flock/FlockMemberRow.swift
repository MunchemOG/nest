import NestKit
import SwiftUI

/// One bird in the overview: its tile, name, status and what it is doing. It reacts once per new action.
struct FlockMemberRow: View {
    let bird: Bird
    let status: BirdStatus
    let doing: String?
    let reactions: Int

    @Environment(\.accessibilityReduceMotion) private var systemReduceMotion
    @Environment(\.reduceMotionOverride) private var reduceMotionOverride

    private var reduceMotion: Bool { reduceMotionOverride ?? systemReduceMotion }

    var body: some View {
        let shape = RoundedRectangle(cornerRadius: NestRadius.lg, style: .continuous)
        HStack(alignment: .top, spacing: NestSpace.s4) {
            BirdAvatar(bird, size: .medium, state: BirdAvatarState(status))
                .phaseAnimator([false, true], trigger: reactions) { avatar, lifted in
                    avatar.offset(y: lifted && !reduceMotion ? NestEffect.liftHover : 0)
                } animation: { _ in
                    .nest(NestMotion.base)
                }
            VStack(alignment: .leading, spacing: NestSpace.s2) {
                HStack(spacing: NestSpace.s3) {
                    Text(bird.name)
                        .nestFont(.title)
                        .foregroundStyle(Color(NestColor.textPrimary))
                    StatusPill(.bird(bird, status))
                }
                Text(doing ?? "Not heard from yet")
                    .nestFont(.bodyS)
                    .foregroundStyle(Color(NestColor.textSecondary))
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer(minLength: 0)
        }
        .padding(NestSpace.s3)
        .background {
            shape.fill(Color(bird.tint))
                .phaseAnimator([false, true], trigger: reactions) { wash, washed in
                    wash.opacity(washed ? 1 : 0)
                } animation: { _ in
                    .nest(NestMotion.base)
                }
        }
        .accessibilityElement(children: .combine)
        .accessibilityIdentifier("flock.\(bird.rawValue)")
    }
}
