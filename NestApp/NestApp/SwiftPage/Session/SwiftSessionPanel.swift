import NestKit
import SwiftUI

/// Claude Code in a panel: the project and session up top, the live transcript, and the composer.
/// The close-up and the small Swift both show it; the small one hides the less-used controls.
struct SwiftSessionPanel: View {
    let session: SwiftSessionModel
    let compact: Bool
    let switchProject: () -> Void
    let close: (() -> Void)?

    var body: some View {
        NestPanel(.solid, padding: compact ? NestSpace.s3 : NestSpace.s4) {
            VStack(alignment: .leading, spacing: NestSpace.s3) {
                header
                SwiftTranscriptView(session: session)
                    .frame(maxHeight: .infinity)
                SwiftComposer(session: session, compact: compact)
            }
        }
        .task { await session.refresh() }
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier(compact ? "swift.mini" : "swift.closeup")
    }

    private var header: some View {
        HStack(spacing: NestSpace.s3) {
            Button(action: switchProject) {
                HStack(spacing: NestSpace.s3) {
                    SwiftProjectTileView(project: session.page.project, size: compact ? NestSpace.s5 : NestSpace.s6)
                    VStack(alignment: .leading, spacing: 0) {
                        HStack(spacing: NestSpace.s1) {
                            Text(session.page.project.name)
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
                Button("New session") { session.newSession() }
                if !session.pastSessions.isEmpty {
                    Section("Resume") {
                        ForEach(session.pastSessions.prefix(12)) { past in
                            Button("\(past.title) · \(past.lastActive.formatted(.relative(presentation: .named)))") { session.resume(past) }
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
            Button { session.newSession() } label: {
                Image(systemName: "square.and.pencil").font(.nest(.label))
            }
            .buttonStyle(NestButtonStyle(.quiet, size: .small))
            .help("New session")
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
