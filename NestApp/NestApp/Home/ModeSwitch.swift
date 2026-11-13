import NestKit
import SwiftUI

/// Morning, Focus and Night on a glass pill; the current one sits on a white knob.
struct ModeSwitch: View {
    let mode: String?
    let select: (String) -> Void

    static let modes: [(name: String, symbol: String)] = [("Morning", "sun.max"), ("Focus", "scope"), ("Night", "moon")]

    @Namespace private var knob
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.pixelLength) private var hairline

    var body: some View {
        HStack(spacing: 0) {
            ForEach(Self.modes, id: \.name) { item in
                let isOn = item.name == mode
                Button { select(item.name) } label: {
                    Label(item.name, systemImage: item.symbol)
                        .nestFont(.label)
                        .fixedSize()
                        .foregroundStyle(Color(isOn ? NestColor.surface0 : NestColor.textMuted))
                        .padding(.horizontal, NestSpace.s4)
                        .padding(.vertical, NestSpace.s2)
                        .background {
                            if isOn {
                                Capsule().fill(Color(NestColor.textPrimary)).matchedGeometryEffect(id: "knob", in: knob)
                            }
                        }
                        .contentShape(Capsule())
                }
                .buttonStyle(.plain)
                .accessibilityAddTraits(isOn ? .isSelected : [])
                .accessibilityIdentifier("home.mode.\(item.name.lowercased())")
            }
        }
        .padding(NestSpace.s1)
        .background { Capsule().fill(.ultraThinMaterial) }
        .background { Capsule().fill(Color(NestColor.glass)) }
        .overlay { Capsule().strokeBorder(Color(NestColor.line), lineWidth: hairline) }
        .nestShadow(.panel, in: Capsule())
        .animation(reduceMotion ? nil : .nest(NestMotion.slow), value: mode)
    }
}
