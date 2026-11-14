import NestKit
import SwiftUI

/// One of your plan's limits as Claude Code reports it: its name, how full it is as a bar, the share and when it resets.
struct SwiftLimitRow: View {
    let limit: ClaudeLimit

    var body: some View {
        VStack(alignment: .leading, spacing: NestSpace.s1) {
            HStack(spacing: NestSpace.s2) {
                Text(limit.title)
                    .nestFont(.label)
                    .foregroundStyle(Color(NestColor.textPrimary))
                Spacer(minLength: NestSpace.s2)
                Text(detail)
                    .nestFont(.caption)
                    .monospacedDigit()
                    .foregroundStyle(Color(limit.isCritical ? NestColor.textPrimary : NestColor.textSecondary))
            }
            GeometryReader { space in
                ZStack(alignment: .leading) {
                    Capsule().fill(Color(NestColor.line))
                    Capsule()
                        .fill(Color(Bird.swift.color))
                        .frame(width: space.size.width * min(max(limit.used, 0), 1))
                }
            }
            .frame(height: NestSpace.s1)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(limit.title), \(detail)")
    }

    private var detail: String {
        let share = "\(SwiftPageModel.percent(limit.used)) used"
        return limit.resets.map { "\(share) · \(SwiftPageModel.resets($0))" } ?? share
    }
}
