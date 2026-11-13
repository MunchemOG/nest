import NestKit
import SwiftUI

/// The live activity panel on Home: the newest events, compact, with Undo on hover.
struct ActivityPanel: View {
    let model: HomeModel

    @Environment(\.accessibilityReduceMotion) private var systemReduceMotion
    @Environment(\.reduceMotionOverride) private var reduceMotionOverride

    /// Whether new rows slide in; under reduced motion they only fade.
    static func rowsSlide(reduceMotion: Bool) -> Bool { !reduceMotion }

    var body: some View {
        let reduceMotion = reduceMotionOverride ?? systemReduceMotion
        NestPanel(.solid, padding: NestSpace.s2) {
            VStack(alignment: .leading, spacing: 0) {
                HStack {
                    Text("Activity")
                        .nestFont(.label)
                        .foregroundStyle(Color(NestColor.textPrimary))
                    Spacer()
                    HStack(spacing: NestSpace.s2) {
                        StatusDot(color: .statusSuccess, rest: .statusSuccess, breathes: false, diameter: NestSpace.s1 + NestSpace.s1 / 2)
                        Text("Live")
                            .nestFont(.caption)
                            .foregroundStyle(Color(NestColor.textMuted))
                    }
                }
                .padding(.horizontal, NestSpace.s3)
                .padding(.vertical, NestSpace.s2)
                ForEach(model.feed.prefix(3), id: \.id) { event in
                    ActivityRow(event, isUndone: model.isUndone(event), isCompact: true, publish: model.publish)
                        .transition(Self.rowsSlide(reduceMotion: reduceMotion) ? .opacity.combined(with: .move(edge: .top)) : .opacity)
                }
                if model.feed.isEmpty {
                    Text("Nothing yet today.")
                        .nestFont(.bodyS)
                        .foregroundStyle(Color(NestColor.textMuted))
                        .padding(NestSpace.s3)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .animation(.nest(NestMotion.base), value: model.feed.map(\.id))
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("home.feed")
    }
}
