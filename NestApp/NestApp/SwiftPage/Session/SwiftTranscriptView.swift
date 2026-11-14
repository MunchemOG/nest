import NestKit
import SwiftUI

/// The session as it happens: your messages, Claude's replies, the tools it used, its requests, and each turn's end.
/// It follows the newest line unless you've scrolled up.
struct SwiftTranscriptView: View {
    let session: SwiftSessionModel

    var body: some View {
        ScrollViewReader { scroller in
            ScrollView {
                LazyVStack(alignment: .leading, spacing: NestSpace.s3) {
                    if session.transcript.items.isEmpty { empty }
                    ForEach(session.transcript.items) { item in
                        row(item).id(item.id)
                    }
                    if session.isWorking && session.transcript.waiting == nil {
                        TypingDots().frame(height: NestFont.body.lineHeight).id("working")
                    }
                }
                .padding(.vertical, NestSpace.s3)
            }
            .onChange(of: session.transcript.items.last?.text) {
                if let last = session.transcript.items.last { scroller.scrollTo(last.id, anchor: .bottom) }
            }
            .onChange(of: session.transcript.items.count) {
                if let last = session.transcript.items.last { scroller.scrollTo(last.id, anchor: .bottom) }
            }
        }
        .accessibilityIdentifier("swift.transcript")
    }

    @ViewBuilder
    private func row(_ item: TranscriptItem) -> some View {
        switch item.kind {
        case .you:
            SwiftYouBubble(text: item.text)
        case .claude:
            SwiftClaudeText(text: item.text, isStreaming: item.isStreaming)
        case .tool:
            if let tool = item.tool { SwiftToolCardView(card: tool) }
        case .permission:
            if let permission = item.permission {
                SwiftPermissionCard(permission: permission) { answer in
                    Task { await session.answer(permission.request, with: answer) }
                }
            }
        case .finished:
            Text(item.text)
                .nestFont(.caption)
                .foregroundStyle(Color(NestColor.textMuted))
                .frame(maxWidth: .infinity)
        }
    }

    private var empty: some View {
        VStack(alignment: .leading, spacing: NestSpace.s2) {
            Text("Claude Code in \(session.project.name)")
                .nestFont(.title)
                .foregroundStyle(Color(NestColor.textPrimary))
            Text("Runs in \(session.project.folder.replacingOccurrences(of: NSHomeDirectory(), with: "~")) with its own CLAUDE.md and memory. Nothing from your other projects comes in.")
                .nestFont(.bodyS)
                .foregroundStyle(Color(NestColor.textSecondary))
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.top, NestSpace.s6)
    }
}
