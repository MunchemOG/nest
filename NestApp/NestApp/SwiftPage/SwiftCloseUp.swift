import NestKit
import SwiftUI

/// The left of Swift's cockpit: its name and what it's doing, your projects, a chat that takes plain words, and the queue.
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
                HStack(spacing: NestSpace.s2) {
                    StatusPill(.bird(.swift, building == nil ? .resting : .active))
                    Text(doing)
                        .nestFont(.caption)
                        .foregroundStyle(Color(NestColor.textSecondary))
                        .lineLimit(1)
                }
                SwiftProjectPills(page: page)
                Text(rulesLine)
                    .nestFont(.caption)
                    .foregroundStyle(Color(NestColor.textMuted))
                    .lineLimit(2)
                    .accessibilityIdentifier("swift.project.rules")
                SwiftSection("Talk") {
                    ScrollViewReader { scroller in
                        ScrollView {
                            VStack(alignment: .leading, spacing: NestSpace.s2) {
                                ForEach(page.messages) { ChatBubble($0) }
                                if page.isThinking { TypingBubble(.swift).id("thinking") }
                            }
                        }
                        .frame(maxHeight: NestSpace.s10 + NestSpace.s8)
                        .onChange(of: page.messages.count) {
                            if let last = page.messages.last { scroller.scrollTo(last.id, anchor: .bottom) }
                        }
                    }
                    ChatComposer(draft: $draft, placeholder: "Tell Swift what to build…") { text in
                        Task { await page.send(text) }
                    }
                    .accessibilityIdentifier("swift.chat")
                }
                SwiftSection(page.tonight.isEmpty ? "Queue" : "Queue · \(page.tonight.count)") {
                    if page.tonight.isEmpty {
                        Text("Nothing queued for \(page.project.name).")
                            .nestFont(.bodyS)
                            .foregroundStyle(Color(NestColor.textMuted))
                    }
                    ScrollView {
                        VStack(spacing: 0) {
                            ForEach(page.tonight, id: \.id) { task in
                                SwiftQueueRow(task: task, defaults: page.project.defaults) { run in
                                    Task { await page.setRun(run, for: task.id) }
                                }
                            }
                        }
                    }
                    .frame(maxHeight: NestSpace.s10 + NestSpace.s7)
                }
            }
        }
        .task {
            while !Task.isCancelled {
                await page.refresh()
                try? await Task.sleep(for: .seconds(30))
            }
        }
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("swift.closeup")
    }

    private var building: QueuedTask? { page.tonight.first { $0.state == .claimed } }

    private var doing: String {
        if let building { return "Building \(building.id) in \(page.project.name)" }
        let waiting = page.tonight.count
        return waiting == 0 ? "Nothing waiting" : "\(waiting) waiting · builds once you're away"
    }

    private var rulesLine: String {
        let project = page.project
        let tests = project.tests == nil ? "no tests" : "tests: \(page.testsLine)"
        let merging = project.merges ? "merges green work" : "leaves work on its branch"
        return "\(project.folder.replacingOccurrences(of: NSHomeDirectory(), with: "~")) · \(tests) · \(merging)"
    }
}
