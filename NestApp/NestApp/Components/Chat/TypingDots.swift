import NestKit
import SwiftUI

/// Three dots that light up in turn while a bird is writing.
struct TypingDots: View {
    @Environment(\.accessibilityReduceMotion) private var systemReduceMotion
    @Environment(\.reduceMotionOverride) private var reduceMotionOverride

    /// One phase per dot.
    static let phases = [0, 1, 2]

    /// Which dot is lit in a phase.
    static func brightDot(phase: Int) -> Int { phase % phases.count }

    /// Whether the dots step at all; under reduced motion they hold still.
    static func steps(reduceMotion: Bool) -> Bool { !reduceMotion }

    var body: some View {
        if Self.steps(reduceMotion: reduceMotionOverride ?? systemReduceMotion) {
            dots(lit: nil).phaseAnimator(Self.phases) { _, phase in
                dots(lit: Self.brightDot(phase: phase))
            } animation: { _ in
                .nest(NestMotion.slow, NestMotion.easeInOut)
            }
        } else {
            dots(lit: nil)
        }
    }

    private func dots(lit: Int?) -> some View {
        HStack(spacing: NestSpace.s1) {
            ForEach(Self.phases, id: \.self) { index in
                Circle()
                    .fill(Color(index == lit ? NestColor.textPrimary : NestColor.textMuted))
                    .frame(width: NestSpace.s2, height: NestSpace.s2)
            }
        }
        .accessibilityLabel("Writing")
    }
}
