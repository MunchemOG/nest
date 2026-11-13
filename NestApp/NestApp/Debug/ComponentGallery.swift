#if DEBUG
import NestKit
import SwiftUI

/// Every component in one scrolling window, for checking them by eye and by UI test.
struct ComponentGallery: View {
    static let windowID = "gallery"

    private struct Row: Identifiable {
        let id: String
        let bird: Bird
        let text: String
    }

    private let rows = [
        Row(id: "a", bird: .wren, text: "Wren moved swerve-pod-v4.step to Robotics / CAD"),
        Row(id: "b", bird: .crow, text: "Crow pitched a tool that names STEP exports"),
        Row(id: "c", bird: .swift, text: "Swift merged N1-13 with 17 new tests"),
    ]

    @State private var selection = CardSelection<String>(selected: "b")
    @State private var draft = ChatDraft()
    @State private var showsFloating = false
    @State private var lastPublished = "Nothing published yet"

    private let activity: [NestEvent] = {
        let events = (try? DemoDay.events()) ?? []
        let wanted = ["Swift merged N1-13 with 17 new tests", "Swift merged N1-14 with 9 new tests", "Swift rolled back the N1-14 merge"]
        return wanted.compactMap { summary in events.first { $0.summary == summary } }
    }()

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: NestSpace.s7) {
                section("Type", id: "gallery.type") { TypeSpecimen() }
                section("Buttons", id: "gallery.button") { buttons }
                section("Tags", id: "gallery.tag") { tags }
                section("Status pills", id: "gallery.status-pill") { pills }
                section("Bird avatars", id: "gallery.avatar") { avatars }
                section("Cards", id: "gallery.card") {
                    NestCardList(rows, selection: $selection, bird: \.bird) { row in
                        Text(row.text).nestFont(.bodyS).foregroundStyle(Color(NestColor.textPrimary))
                    }
                }
                section("Solid panel", id: "gallery.panel-solid") {
                    NestPanel(.solid) {
                        Text("Activity").nestFont(.title).foregroundStyle(Color(NestColor.textPrimary))
                    }
                }
                section("Floating panel", id: "gallery.panel-floating") {
                    Button("Show floating panel") { showsFloating = true }
                        .buttonStyle(NestButtonStyle(.secondary))
                }
                section("Activity rows", id: "gallery.activity-row") { activityRows }
                section("Chat", id: "gallery.chat-bubble") {
                    VStack(alignment: .leading, spacing: NestSpace.s3) {
                        ChatBubble(ChatMessage(id: "1", sender: .bird(.wren), text: "Moved swerve-pod-v4.step to Robotics / CAD."))
                        ChatBubble(ChatMessage(id: "2", sender: .you, text: "Focus mode for two hours, please."))
                    }
                }
                section("Typing", id: "gallery.typing") { TypingBubble(.swift) }
                section("Composer", id: "gallery.composer") {
                    ChatComposer(draft: $draft, placeholder: "Ask the flock") { _ in }
                }
            }
            .padding(NestSpace.s7)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .background(Color(NestColor.surface0))
        .nestFloatingPanel(isPresented: $showsFloating) {
            Text("Escape or a click outside closes this.")
                .nestFont(.body)
                .foregroundStyle(Color(NestColor.textPrimary))
        }
    }

    private var buttons: some View {
        VStack(alignment: .leading, spacing: NestSpace.s3) {
            ForEach(NestButtonSize.allCases, id: \.self) { size in
                HStack(spacing: NestSpace.s2) {
                    ForEach(NestButtonVariant.allCases, id: \.self) { variant in
                        Button(variant.rawValue.capitalized) {}.buttonStyle(NestButtonStyle(variant, size: size))
                    }
                    Button("Disabled") {}.buttonStyle(NestButtonStyle(.primary, size: size)).disabled(true)
                }
            }
        }
    }

    private var activityRows: some View {
        let ledger = UndoLedger(events: activity)
        return VStack(alignment: .leading, spacing: NestSpace.s1) {
            ForEach(activity, id: \.id) { event in
                ActivityRow(event, isUndone: ledger.isUndone(event.id)) { ask in
                    let target = if case .string(let id) = ask.data["target"] { id } else { "" }
                    lastPublished = "\(ask.topic.rawValue) \(target)"
                }
            }
            Text(lastPublished)
                .nestFont(.code)
                .foregroundStyle(Color(NestColor.textMuted))
                .accessibilityIdentifier("gallery.last-published")
        }
    }

    private var tags: some View {
        HStack(spacing: NestSpace.s2) {
            ForEach(NestTagKind.allCases, id: \.self) { NestTag($0.name, kind: $0) }
        }
    }

    private var pills: some View {
        HStack(spacing: NestSpace.s2) {
            ForEach(BirdStatus.allCases, id: \.self) { StatusPill(.bird(.swift, $0)) }
            StatusPill(.success("Passed"))
            StatusPill(.warning("Needs a look"))
            StatusPill(.danger("Failed"))
        }
    }

    private var avatars: some View {
        VStack(alignment: .leading, spacing: NestSpace.s4) {
            ForEach(BirdAvatarSize.allCases, id: \.self) { size in
                HStack(spacing: NestSpace.s4) {
                    ForEach(Bird.allCases, id: \.self) { bird in
                        BirdAvatar(bird, size: size, state: bird == .swift ? .active : bird == .crow ? .paused : .resting)
                    }
                }
            }
        }
    }

    private func section(_ title: String, id: String, @ViewBuilder content: () -> some View) -> some View {
        VStack(alignment: .leading, spacing: NestSpace.s4) {
            Text(title).nestFont(.title).foregroundStyle(Color(NestColor.textSecondary))
            content()
        }
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier(id)
    }
}

#Preview {
    ComponentGallery()
}
#endif
