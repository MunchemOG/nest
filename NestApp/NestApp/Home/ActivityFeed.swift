import NestKit
import SwiftUI

/// The newest events on a glass panel, each with one-tap Undo or Redo.
struct ActivityFeed: View {
    let model: HomeModel

    @Environment(\.accessibilityReduceMotion) private var systemReduceMotion
    @Environment(\.reduceMotionOverride) private var reduceMotionOverride

    var body: some View {
        let reduceMotion = reduceMotionOverride ?? systemReduceMotion
        NestPanel(.solid, padding: NestSpace.s2) {
            VStack(alignment: .leading, spacing: 0) {
                ForEach(model.feed, id: \.id) { event in
                    ActivityRow(event, isUndone: model.isUndone(event), publish: model.publish)
                        .transition(reduceMotion ? .opacity : .opacity.combined(with: .move(edge: .top)))
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
