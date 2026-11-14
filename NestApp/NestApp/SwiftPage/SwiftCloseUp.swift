import NestKit
import SwiftUI

/// Swift's close-up panel on the left of Home: its name, then Chat, Tonight, Usage and Boundaries.
struct SwiftCloseUp: View {
    let page: SwiftPageModel
    let close: () -> Void

    @State private var draft = ChatDraft()

    var body: some View {
        NestPanel(.solid, padding: NestSpace.s4) {
            VStack(alignment: .leading, spacing: NestSpace.s4) {
                HStack(alignment: .firstTextBaseline) {
                    Text(Bird.swift.name)
                        .nestFont(.displayXL)
                        .foregroundStyle(Color(Bird.swift.color))
                    Spacer()
                    Button("Close", action: close)
                        .buttonStyle(NestButtonStyle(.quiet, size: .small))
                        .accessibilityIdentifier("swift.close")
                }
                section("Chat") {
                    ScrollView {
                        VStack(alignment: .leading, spacing: NestSpace.s2) {
                            ForEach(page.messages) { ChatBubble($0) }
                        }
                    }
                    .frame(maxHeight: NestSpace.s10 * 2)
                    ChatComposer(draft: $draft, placeholder: "Add a task: … Done means: …") { text in
                        Task { await page.send(text) }
                    }
                    .accessibilityIdentifier("swift.chat")
                }
                section("Tonight") {
                    if page.tonight.isEmpty {
                        Text("Nothing queued.")
                            .nestFont(.bodyS)
                            .foregroundStyle(Color(NestColor.textMuted))
                    }
                    ForEach(page.tonight, id: \.id) { task in
                        HStack(alignment: .firstTextBaseline, spacing: NestSpace.s2) {
                            Text(task.id)
                                .nestFont(.label)
                                .monospacedDigit()
                                .foregroundStyle(Color(NestColor.textPrimary))
                            Text(task.goal)
                                .nestFont(.bodyS)
                                .foregroundStyle(Color(NestColor.textSecondary))
                                .fixedSize(horizontal: false, vertical: true)
                        }
                        .accessibilityElement(children: .combine)
                        .accessibilityIdentifier("swift.queue.row")
                    }
                }
                section("Usage") {
                    Text(page.usage)
                        .nestFont(.bodyS)
                        .foregroundStyle(Color(NestColor.textSecondary))
                }
                section("Boundaries") {
                    ForEach(page.boundaries, id: \.self) { line in
                        Text(line)
                            .nestFont(.bodyS)
                            .foregroundStyle(Color(NestColor.textSecondary))
                    }
                }
            }
        }
        .task { await page.refresh() }
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("swift.closeup")
    }

    private func section(_ title: String, @ViewBuilder content: () -> some View) -> some View {
        VStack(alignment: .leading, spacing: NestSpace.s2) {
            Text(title)
                .nestFont(.label)
                .foregroundStyle(Color(NestColor.textMuted))
            content()
        }
    }
}
