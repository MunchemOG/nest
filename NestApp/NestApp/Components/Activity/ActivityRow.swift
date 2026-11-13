import NestKit
import SwiftUI

/// One line in the activity feed: who did what and when, with one-tap Undo or Redo.
struct ActivityRow: View {
    let event: NestEvent
    let isUndone: Bool
    let isCompact: Bool
    let publish: @MainActor (NestEvent) -> Void

    @Environment(\.timeZone) private var timeZone
    @State private var isHovered = false

    init(_ event: NestEvent, isUndone: Bool, isCompact: Bool = false, publish: @escaping @MainActor (NestEvent) -> Void) {
        self.event = event
        self.isUndone = isUndone
        self.isCompact = isCompact
        self.publish = publish
    }

    /// The sentence shown: in a compact row the bird's name is dropped, since the line under it names the bird.
    var sentence: String {
        guard isCompact, let bird = event.sender.bird, event.summary.hasPrefix(bird.name + " ") else { return event.summary }
        let rest = event.summary.dropFirst(bird.name.count + 1)
        return rest.prefix(1).uppercased() + rest.dropFirst()
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
                Text(sentence)
                    .nestFont(.bodyS)
                    .strikethrough(isUndone)
                    .foregroundStyle(Color(isUndone ? NestColor.textMuted : NestColor.textPrimary))
                    .lineLimit(isCompact ? 2 : nil)
                    .fixedSize(horizontal: false, vertical: true)
                Text(meta(in: timeZone))
                    .nestFont(.caption)
                    .monospacedDigit()
                    .foregroundStyle(Color(NestColor.textMuted))
            }
            Spacer(minLength: NestSpace.s2)
            control
                .opacity(isCompact && !isHovered ? 0 : 1)
        }
        .padding(.horizontal, NestSpace.s3)
        .padding(.vertical, NestSpace.s2)
        .background {
            if isCompact {
                RoundedRectangle(cornerRadius: NestRadius.md, style: .continuous)
                    .fill(Color(isHovered ? NestColor.line : .surface0).opacity(isHovered ? 1 : 0))
            }
        }
        .onHover { isHovered = $0 }
        .animation(.nest(NestMotion.fast), value: isHovered)
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
