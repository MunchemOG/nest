import NestKit
import SwiftUI

/// Claude Code in a panel: your open sessions as tabs, the front one's project and session, its live transcript,
/// and the composer. The close-up and the small Swift both show it; the small one hides the less-used controls.
struct SwiftSessionPanel: View {
    let sessions: SwiftSessions
    let compact: Bool
    let switchProject: () -> Void
    let close: (() -> Void)?

    private var session: SwiftSessionModel { sessions.current }

    /// A panel over `sessions`, opening the launcher with `switchProject` and closing with `close`.
    init(sessions: SwiftSessions, compact: Bool, switchProject: @escaping () -> Void, close: (() -> Void)?) {
        self.sessions = sessions
        self.compact = compact
        self.switchProject = switchProject
        self.close = close
    }

    /// A panel over the one session `session`.
    init(session: SwiftSessionModel, compact: Bool, switchProject: @escaping () -> Void, close: (() -> Void)?) {
        self.init(sessions: SwiftSessions(holding: session), compact: compact, switchProject: switchProject, close: close)
    }

    var body: some View {
        NestPanel(.solid, padding: compact ? NestSpace.s3 : NestSpace.s4) {
            VStack(alignment: .leading, spacing: NestSpace.s3) {
                header
                SwiftSessionTabs(sessions: sessions)
                SwiftTranscriptView(session: session)
                    .frame(maxHeight: .infinity)
                    .id(ObjectIdentifier(session))
                SwiftComposer(session: session, compact: compact)
                    .id(ObjectIdentifier(session))
            }
        }
        .task(id: ObjectIdentifier(session)) { await session.refresh() }
        .task {
            guard !compact else { return }
            while !Task.isCancelled {
                await sessions.current.checkUsage()
                try? await Task.sleep(for: .seconds(300))
            }
        }
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier(compact ? "swift.mini" : "swift.closeup")
    }

    private var header: some View {
        HStack(spacing: NestSpace.s3) {
            Button(action: switchProject) {
                HStack(spacing: NestSpace.s3) {
                    SwiftProjectTileView(project: session.project, size: compact ? NestSpace.s5 : NestSpace.s6)
                    VStack(alignment: .leading, spacing: 0) {
                        HStack(spacing: NestSpace.s1) {
                            Text(session.project.name)
                                .nestFont(.title)
                                .foregroundStyle(Color(NestColor.textPrimary))
                            Image(systemName: "chevron.down")
                                .font(.nest(.caption))
                                .foregroundStyle(Color(NestColor.textMuted))
                        }
                        Text(subtitle)
                            .nestFont(.caption)
                            .foregroundStyle(Color(NestColor.textMuted))
                            .lineLimit(1)
                    }
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .help("Switch project")
            .accessibilityIdentifier("swift.project")
            Spacer(minLength: NestSpace.s2)
            Menu {
                Button("New session") { sessions.newSession() }
                if !session.pastSessions.isEmpty {
                    Section("Resume") {
                        ForEach(session.pastSessions.prefix(12)) { past in
                            Button("\(past.title) · \(past.lastActive.formatted(.relative(presentation: .named)))") { sessions.resume(past) }
                        }
                    }
                }
            } label: {
                Image(systemName: "clock.arrow.circlepath")
                    .font(.nest(.label))
                    .foregroundStyle(Color(NestColor.textSecondary))
            }
            .menuStyle(.borderlessButton).menuIndicator(.hidden).fixedSize()
            .help("Sessions")
            .accessibilityIdentifier("swift.sessions")
            Button { sessions.newSession() } label: {
                Image(systemName: "square.and.pencil").font(.nest(.label))
            }
            .buttonStyle(NestButtonStyle(.quiet, size: .small))
            .keyboardShortcut("t", modifiers: [.command])
            .help("New session (⌘T)")
            .accessibilityIdentifier("swift.new")
            if let close {
                Button("Close", action: close)
                    .buttonStyle(NestButtonStyle(.quiet, size: .small))
                    .accessibilityIdentifier("swift.close")
            }
        }
    }

    private var subtitle: String {
        let place = session.status.branch.map { branch in
            session.status.changed == 0 ? branch : "\(branch) · \(session.status.changed) changed"
        } ?? "not a git repository"
        return "\(place) · \(session.title ?? (session.sessionID == nil ? "new session" : "this session"))"
    }
}
