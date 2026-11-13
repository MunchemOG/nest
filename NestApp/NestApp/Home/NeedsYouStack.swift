import NestKit
import SwiftUI

/// The things waiting for you, as cards in each bird's colours.
struct NeedsYouStack: View {
    let events: [NestEvent]

    @Environment(\.timeZone) private var timeZone

    var body: some View {
        VStack(alignment: .leading, spacing: NestSpace.s3) {
            ForEach(events, id: \.id) { event in
                NestCardFace(bird: event.sender.bird) {
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
                        }
                        Spacer(minLength: 0)
                    }
                }
            }
            if events.isEmpty {
                Text("Nothing needs you.")
                    .nestFont(.bodyS)
                    .foregroundStyle(Color(NestColor.textMuted))
            }
        }
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("home.needs-you")
    }
}

extension EventSender {
    /// The bird that sent it, if a bird did.
    var bird: Bird? {
        if case .bird(let bird) = self { bird } else { nil }
    }
}
