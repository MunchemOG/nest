import NestKit
import SwiftUI

/// Swift's report, opened in place on its card: status and health, a dot per task, the headline and the points.
struct ReportDetailsView: View {
    let details: ReportDetails

    var body: some View {
        VStack(alignment: .leading, spacing: NestSpace.s2) {
            HStack(spacing: NestSpace.s2) {
                StatusDot(color: ReportDetails.color(for: details.status), rest: ReportDetails.color(for: details.status), breathes: false)
                Text(details.status.rawValue.capitalized)
                    .nestFont(.label)
                    .foregroundStyle(Color(NestColor.textPrimary))
                if let health = details.health {
                    Text(health)
                        .nestFont(.caption)
                        .foregroundStyle(Color(NestColor.textMuted))
                }
            }
            if !details.tasks.isEmpty {
                HStack(spacing: NestSpace.s1) {
                    ForEach(Array(details.tasks.enumerated()), id: \.offset) { _, ending in
                        StatusDot(color: ReportDetails.color(for: ending), rest: ReportDetails.color(for: ending), breathes: false)
                    }
                }
                .accessibilityElement(children: .ignore)
                .accessibilityLabel(details.tasks.map(\.rawValue).joined(separator: ", "))
            }
            Text(details.headline)
                .nestFont(.bodyS)
                .foregroundStyle(Color(NestColor.textPrimary))
                .fixedSize(horizontal: false, vertical: true)
            ForEach(Array(details.points.enumerated()), id: \.offset) { _, point in
                HStack(alignment: .firstTextBaseline, spacing: NestSpace.s2) {
                    if !point.figure.isEmpty {
                        Text(point.figure)
                            .nestFont(.label)
                            .monospacedDigit()
                            .foregroundStyle(Color(NestColor.textPrimary))
                    }
                    Text(point.text)
                        .nestFont(.bodyS)
                        .foregroundStyle(Color(NestColor.textSecondary))
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
        .padding(.top, NestSpace.s2)
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("report.points")
    }
}
