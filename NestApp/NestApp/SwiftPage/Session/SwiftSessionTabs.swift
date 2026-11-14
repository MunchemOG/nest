import NestKit
import SwiftUI

/// Your open sessions as tabs, like Claude Code in several terminal tabs: each with its project's tile, its name,
/// a dot while Claude works (or waits for you), and a close button; the last button opens another.
struct SwiftSessionTabs: View {
    let sessions: SwiftSessions

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: NestSpace.s1) {
                ForEach(sessions.sessions) { session in
                    tab(session)
                }
                Button { sessions.newSession() } label: {
                    Image(systemName: "plus")
                        .font(.nest(.caption))
                        .foregroundStyle(Color(NestColor.textSecondary))
                        .padding(NestSpace.s2)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .help("New session (⌘T)")
                .accessibilityIdentifier("swift.tabs.new")
            }
        }
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("swift.tabs")
    }

    private func tab(_ session: SwiftSessionModel) -> some View {
        let isFront = session === sessions.current
        let shape = RoundedRectangle(cornerRadius: NestRadius.md, style: .continuous)
        return HStack(spacing: NestSpace.s2) {
            Button { sessions.show(session) } label: {
                HStack(spacing: NestSpace.s2) {
                    SwiftProjectTileView(project: session.project, size: NestSpace.s4)
                    Text(session.tabTitle)
                        .nestFont(.label)
                        .lineLimit(1)
                        .frame(maxWidth: NestSpace.s10 + NestSpace.s8, alignment: .leading)
                        .foregroundStyle(Color(isFront ? NestColor.textPrimary : NestColor.textSecondary))
                    if session.isWaiting || session.isWorking {
                        Circle()
                            .fill(Color(session.isWaiting ? NestColor.clay : Bird.swift.color))
                            .frame(width: NestSpace.s2, height: NestSpace.s2)
                            .help(session.isWaiting ? "Waiting for you" : "Claude is working")
                    }
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .help("\(session.project.name) · \(session.tabTitle)")
            Button { sessions.close(session) } label: {
                Image(systemName: "xmark")
                    .font(.nest(.caption))
                    .foregroundStyle(Color(NestColor.textMuted))
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .help("Close this session; Claude Code stops")
            .accessibilityIdentifier("swift.tabs.close")
        }
        .padding(.horizontal, NestSpace.s2)
        .padding(.vertical, NestSpace.s1)
        .background { shape.fill(isFront ? Color(NestColor.line) : Color.clear) }
        .accessibilityElement(children: .contain)
        .accessibilityAddTraits(isFront ? .isSelected : [])
        .accessibilityIdentifier("swift.tab")
    }
}
