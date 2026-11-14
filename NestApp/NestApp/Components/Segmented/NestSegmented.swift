import NestKit
import SwiftUI

/// A row of choices on a glass pill; the chosen one sits on a white knob that slides to the next (it jumps under reduced motion).
struct NestSegmented<Value: Hashable>: View {
    let options: [(value: Value, title: String)]
    let selection: Value
    let id: String
    let select: (Value) -> Void

    @Namespace private var knob
    @Environment(\.accessibilityReduceMotion) private var systemReduceMotion
    @Environment(\.reduceMotionOverride) private var reduceMotionOverride
    @Environment(\.pixelLength) private var hairline

    var body: some View {
        HStack(spacing: 0) {
            ForEach(options, id: \.value) { option in
                let isOn = option.value == selection
                Button { select(option.value) } label: {
                    Text(option.title)
                        .nestFont(.label)
                        .lineLimit(1)
                        .fixedSize()
                        .foregroundStyle(Color(isOn ? NestColor.surface0 : NestColor.textSecondary))
                        .padding(.horizontal, NestSpace.s3)
                        .padding(.vertical, NestSpace.s1)
                        .frame(maxWidth: .infinity)
                        .background {
                            if isOn {
                                Capsule().fill(Color(NestColor.textPrimary)).matchedGeometryEffect(id: "knob", in: knob)
                            }
                        }
                        .contentShape(Capsule())
                }
                .buttonStyle(.plain)
                .accessibilityAddTraits(isOn ? .isSelected : [])
                .accessibilityIdentifier("\(id).\(option.title.lowercased())")
            }
        }
        .padding(NestSpace.s1 / 2)
        .background { Capsule().fill(Color(NestColor.line)) }
        .overlay { Capsule().strokeBorder(Color(NestColor.line), lineWidth: hairline) }
        .animation(reduceMotionOverride ?? systemReduceMotion ? nil : .nest(NestMotion.base), value: selection)
    }
}
