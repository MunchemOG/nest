import NestKit
import SwiftUI

/// Fourteen small bars, one per day: how much you worked with Claude Code in a project, oldest on the left.
struct SwiftActivityStrip: View {
    let counts: [Int]

    var body: some View {
        let most = max(counts.max() ?? 0, 1)
        HStack(alignment: .bottom, spacing: NestSpace.s1 / 2) {
            ForEach(Array(counts.enumerated()), id: \.offset) { _, count in
                RoundedRectangle(cornerRadius: NestSpace.s1 / 2)
                    .fill(Color(count == 0 ? NestColor.line : NestColor.lineStrong))
                    .frame(height: max(NestSpace.s1 / 2, NestSpace.s5 * Double(count) / Double(most)))
                    .frame(maxWidth: .infinity)
            }
        }
        .frame(height: NestSpace.s5, alignment: .bottom)
        .accessibilityLabel("Activity over the last \(counts.count) days")
    }
}
