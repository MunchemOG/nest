import NestKit
import SwiftUI

/// The date and time, and the mode switch.
struct HomeTopBar: View {
    let now: Date?
    let mode: String?
    let switchMode: (String) -> Void

    @Environment(\.timeZone) private var timeZone
    @Environment(\.locale) private var locale

    var body: some View {
        HStack(spacing: NestSpace.s5) {
            if let now {
                HStack(spacing: NestSpace.s2) {
                    Text(now.formatted(Date.FormatStyle(locale: locale, timeZone: timeZone).weekday(.wide).day().month(.wide)))
                        .foregroundStyle(Color(NestColor.textMuted))
                    Text(now.formatted(Date.VerbatimFormatStyle(
                        format: "\(hour: .twoDigits(clock: .twentyFourHour, hourCycle: .zeroBased)):\(minute: .twoDigits)",
                        timeZone: timeZone, calendar: Calendar(identifier: .gregorian)
                    )))
                    .foregroundStyle(Color(NestColor.textSecondary))
                    .monospacedDigit()
                }
                .nestFont(.label)
                .fixedSize()
            }
            ModeSwitch(mode: mode, select: switchMode)
        }
    }
}
