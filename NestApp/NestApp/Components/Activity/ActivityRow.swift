import NestKit
import SwiftUI

/// One line in the activity feed: who did what and when, with one-tap Undo or Redo.
struct ActivityRow: View {
    let event: NestEvent
    let isUndone: Bool
    let publish: @MainActor (NestEvent) -> Void

    @Environment(\.timeZone) private var timeZone

    init(_ event: NestEvent, isUndone: Bool, publish: @escaping @MainActor (NestEvent) -> Void) {
        self.event = event
        self.isUndone = isUndone
        self.publish = publish
    }

    /// The control this row offers.
    var choice: UndoChoice { UndoChoice(for: event, isUndone: isUndone) }

    /// "Swift · 13:30": who published it and when, in `timeZone`.
    func meta(in timeZone: TimeZone) -> String {
        let time = Date.VerbatimFormatStyle(
            format: "\(hour: .twoDigits(clock: .twentyFourHour, hourCycle: .zeroBased)):\(minute: .twoDigits)",
            timeZone: timeZone,
            calendar: Calendar(identifier: .gregorian)
        )
        return "\(senderName) · \(event.ts.formatted(time))"
    }

    private var senderName: String {
        switch event.sender {
        case .bird(let bird): bird.name
        case .you: "You"
        case .app: "Nest"
        }
    }

    var body: some View {
        HStack(alignment: .top, spacing: NestSpace.s3) {
            avatar
            VStack(alignment: .leading, spacing: NestSpace.s1) {
                Text(event.summary)
                    .nestFont(.bodyS)
                    .strikethrough(isUndone)
                    .foregroundStyle(Color(isUndone ? NestColor.textMuted : NestColor.textPrimary))
                    .fixedSize(horizontal: false, vertical: true)
                Text(meta(in: timeZone))
                    .nestFont(.caption)
                    .monospacedDigit()
                    .foregroundStyle(Color(NestColor.textMuted))
            }
            Spacer(minLength: NestSpace.s2)
            control
        }
        .padding(.horizontal, NestSpace.s3)
        .padding(.vertical, NestSpace.s2)
        .accessibilityElement(children: .contain)
    }

    @ViewBuilder private var avatar: some View {
        if case .bird(let bird) = event.sender {
            BirdAvatar(bird)
        } else {
            Color.clear.frame(width: BirdAvatarSize.small.side, height: BirdAvatarSize.small.side)
        }
    }

    @ViewBuilder private var control: some View {
        switch choice {
        case .undo: button("Undo")
        case .redo: button("Redo")
        case .none: EmptyView()
        }
    }

    /// What tapping the row's Undo or Redo does: asks for this event to be reversed.
    func tap() {
        guard choice != .none else { return }
        publish(.undoAsked(target: event))
    }

    private func button(_ title: String) -> some View {
        Button(title, action: tap)
            .buttonStyle(NestButtonStyle(.quiet, size: .small))
            .accessibilityLabel(title)
    }
}
