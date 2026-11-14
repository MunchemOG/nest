import NestKit
import SwiftUI

/// The glass panel of things waiting for you, with a count and an answer button or two on each.
struct NeedsYouPanel: View {
    let events: [NestEvent]
    let answer: (NestEvent, NeedsYouAction) -> Void

    @Environment(\.timeZone) private var timeZone
    @Environment(\.nestAccent) private var accent
    @Environment(\.accessibilityReduceMotion) private var systemReduceMotion
    @Environment(\.reduceMotionOverride) private var reduceMotionOverride
    @State private var opened: Set<String> = []

    var body: some View {
        NestPanel(.solid, padding: NestSpace.s2) {
            VStack(alignment: .leading, spacing: 0) {
                HStack {
                    Text("Needs you")
                        .nestFont(.label)
                        .foregroundStyle(Color(NestColor.textPrimary))
                    Spacer()
                    if !events.isEmpty {
                        Text("\(events.count)")
                            .nestFont(.caption)
                            .monospacedDigit()
                            .foregroundStyle(Color(accent.onFill))
                            .padding(.horizontal, NestSpace.s2)
                            .frame(minWidth: NestSpace.s5)
                            .background { Capsule().fill(Color(accent.fill)) }
                    }
                }
                .padding(.horizontal, NestSpace.s3)
                .padding(.vertical, NestSpace.s2)
                ForEach(events, id: \.id) { event in
                    item(event)
                }
                if events.isEmpty {
                    Text("Nothing needs you.")
                        .nestFont(.bodyS)
                        .foregroundStyle(Color(NestColor.textMuted))
                        .padding(NestSpace.s3)
                }
            }
        }
        .animation(.nest(NestMotion.base), value: events.map(\.id))
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("home.needs-you")
    }

    private func item(_ event: NestEvent) -> some View {
        HStack(alignment: .top, spacing: NestSpace.s3) {
            if let bird = event.sender.bird { BirdAvatar(bird) }
            VStack(alignment: .leading, spacing: NestSpace.s1) {
                Text(event.summary)
                    .nestFont(.bodyS)
                    .foregroundStyle(Color(NestColor.textPrimary))
                    .fixedSize(horizontal: false, vertical: true)
                Text(ActivityRow(event, isUndone: false) { _ in }.meta(in: timeZone))
                    .nestFont(.caption)
                    .monospacedDigit()
                    .foregroundStyle(Color(NestColor.textMuted))
                if let details = ReportDetails(event), opened.contains(event.id) {
                    ReportDetailsView(details: details)
                        .transition(.opacity)
                }
                HStack(spacing: NestSpace.s2) {
                    ForEach(Array(NeedsYouAction.actions(for: event).enumerated()), id: \.offset) { index, action in
                        Button(action.title) { answer(event, action) }
                            .buttonStyle(NestButtonStyle(index == 0 ? .solid : .secondary, size: .small))
                    }
                    if ReportDetails(event) != nil {
                        Button(opened.contains(event.id) ? "Hide details" : "Details") { toggleDetails(of: event) }
                            .buttonStyle(NestButtonStyle(.quiet, size: .small))
                            .accessibilityIdentifier("report.details")
                    }
                }
                .padding(.top, NestSpace.s2)
            }
            Spacer(minLength: 0)
        }
        .padding(NestSpace.s3)
        .transition(.opacity)
    }

    /// Opens or closes a report's details in place, without movement under reduced motion.
    private func toggleDetails(of event: NestEvent) {
        let reduceMotion = reduceMotionOverride ?? systemReduceMotion
        withAnimation(reduceMotion ? nil : .nest(NestMotion.base)) {
            if opened.contains(event.id) { opened.remove(event.id) } else { opened.insert(event.id) }
        }
    }
}
