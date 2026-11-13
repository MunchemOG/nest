import NestKit
import SwiftUI

/// While Focus mode runs: a ring in Wren's colour filling toward the end time, and what's left.
struct FocusWidget: View {
    let until: String
    let progress: FocusProgress
    let notificationsOff: Bool

    var body: some View {
        NestPanel(.solid, padding: NestSpace.s4) {
            HStack(spacing: NestSpace.s4) {
                ZStack {
                    Circle().stroke(Color(NestColor.line), lineWidth: NestSpace.s1)
                    Circle()
                        .trim(from: 0, to: progress.fraction)
                        .stroke(Color(Bird.wren.color), style: StrokeStyle(lineWidth: NestSpace.s1, lineCap: .round))
                        .rotationEffect(.degrees(-90))
                    Text("\(Int((progress.fraction * 100).rounded()))%")
                        .nestFont(.label)
                        .monospacedDigit()
                        .foregroundStyle(Color(NestColor.textPrimary))
                }
                .frame(width: NestSpace.s8 - NestSpace.s2, height: NestSpace.s8 - NestSpace.s2)
                VStack(alignment: .leading, spacing: NestSpace.s1) {
                    Text("Focus until \(until)")
                        .nestFont(.title)
                        .foregroundStyle(Color(NestColor.textPrimary))
                    Text("\(progress.minutesLeft) min left" + (notificationsOff ? " · Notifications off" : ""))
                        .nestFont(.caption)
                        .monospacedDigit()
                        .foregroundStyle(Color(NestColor.textSecondary))
                }
                Spacer(minLength: 0)
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityIdentifier("home.focus")
    }
}
