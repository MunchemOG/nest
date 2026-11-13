import NestKit
import SwiftUI

/// A bird's name and status, floating under its tile.
struct FlockTag: View {
    let bird: Bird
    let status: BirdStatus
    let line: String

    @Environment(\.accessibilityReduceMotion) private var systemReduceMotion
    @Environment(\.reduceMotionOverride) private var reduceMotionOverride

    private var kind: StatusPillKind { .bird(bird, status) }

    var body: some View {
        VStack(spacing: NestSpace.s1) {
            Text(bird.name)
                .nestFont(.title)
                .foregroundStyle(Color(NestColor.textPrimary))
            HStack(spacing: NestSpace.s2) {
                StatusDot(
                    color: status == .resting || status == .asleep ? NestColor.textMuted : kind.accent,
                    rest: kind.accentRest,
                    breathes: kind.breathes(reduceMotion: reduceMotionOverride ?? systemReduceMotion),
                    diameter: NestSpace.s1 + NestSpace.s1 / 2
                )
                Text(line)
                    .monospacedDigit()
                    .nestFont(.caption)
                    .foregroundStyle(Color(status == .paused ? NestColor.statusWarning : status == .active ? NestColor.textPrimary : NestColor.textMuted))
            }
        }
        .fixedSize()
        .shadow(color: Color(NestColor.sceneVoid), radius: NestSpace.s3)
        .accessibilityElement(children: .combine)
        .accessibilityIdentifier("flock.\(bird.rawValue)")
    }
}
