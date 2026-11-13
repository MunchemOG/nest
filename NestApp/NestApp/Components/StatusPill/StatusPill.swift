import NestKit
import SwiftUI

/// A pill that says how something is: an icon or dot, then a word.
struct StatusPill: View {
    let kind: StatusPillKind

    @Environment(\.accessibilityReduceMotion) private var systemReduceMotion
    @Environment(\.reduceMotionOverride) private var reduceMotionOverride
    @Environment(\.pixelLength) private var hairline

    private var reduceMotion: Bool { reduceMotionOverride ?? systemReduceMotion }

    init(_ kind: StatusPillKind) {
        self.kind = kind
    }

    var body: some View {
        HStack(spacing: NestSpace.s2) {
            if let symbol = kind.symbol {
                Image(systemName: symbol)
                    .font(.nest(.caption))
                    .foregroundStyle(Color(kind.accent))
            } else {
                StatusDot(color: kind.accent, rest: kind.accentRest, breathes: kind.breathes(reduceMotion: reduceMotion))
            }
            Text(kind.word)
                .nestFont(.caption)
                .foregroundStyle(Color(kind.label))
        }
        .padding(.horizontal, NestSpace.s3)
        .padding(.vertical, NestSpace.s1)
        .background { Capsule().fill(Color(NestColor.surface2)) }
        .overlay { Capsule().strokeBorder(Color(NestColor.line), lineWidth: hairline) }
        .animation(.nest(NestMotion.base), value: kind)
        .accessibilityElement(children: .combine)
    }
}
