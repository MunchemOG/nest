import AppKit
import NestKit
import SwiftUI

/// Choosing a project: every folder you've given Swift as a card, a card to add another (or drop a folder anywhere),
/// and the current project's recent sessions to jump back into. Escape closes it; ⌘1 to ⌘9 open a project.
struct SwiftLauncher: View {
    let session: SwiftSessionModel
    let close: () -> Void

    @State private var isDropping = false
    @Environment(\.pixelLength) private var hairline

    private let columns = Array(repeating: GridItem(.flexible(), spacing: NestSpace.s4), count: 4)

    var body: some View {
        NestPanel(.solid, padding: NestSpace.s6) {
            VStack(alignment: .leading, spacing: NestSpace.s5) {
                HStack {
                    Text("Open a project")
                        .nestFont(.title)
                        .foregroundStyle(Color(NestColor.textPrimary))
                    Spacer()
                    Button("Close", action: close)
                        .buttonStyle(NestButtonStyle(.quiet, size: .small))
                        .keyboardShortcut(.cancelAction)
                }
                ScrollView {
                    LazyVGrid(columns: columns, spacing: NestSpace.s4) {
                        ForEach(Array(session.page.projects.enumerated()), id: \.element.id) { index, project in
                            SwiftProjectCard(project: project, history: session.history,
                                             isCurrent: project.id == session.page.selected,
                                             shortcut: index < 9 ? index + 1 : nil) { open(project.id) }
                        }
                        addCard
                    }
                }
                if !session.pastSessions.isEmpty {
                    VStack(alignment: .leading, spacing: NestSpace.s2) {
                        Text("Recent sessions in \(session.page.project.name)")
                            .nestFont(.caption)
                            .foregroundStyle(Color(NestColor.textMuted))
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: NestSpace.s2) {
                                ForEach(session.pastSessions.prefix(8)) { past in
                                    Button("\(past.title) · \(past.lastActive.formatted(.relative(presentation: .named)))") {
                                        session.resume(past)
                                        close()
                                    }
                                    .buttonStyle(NestButtonStyle(.secondary, size: .small))
                                }
                            }
                        }
                    }
                }
            }
        }
        .dropDestination(for: URL.self) { urls, _ in
            guard let url = urls.first else { return false }
            add(url)
            return true
        } isTargeted: { isDropping = $0 }
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("swift.launcher")
    }

    private var addCard: some View {
        let shape = RoundedRectangle(cornerRadius: NestRadius.xl, style: .continuous)
        return Button(action: pick) {
            VStack(spacing: NestSpace.s2) {
                Image(systemName: "plus").font(.nest(.title))
                Text("Add a folder").nestFont(.label)
                Text("Choose one, or drop it here").nestFont(.caption).foregroundStyle(Color(NestColor.textMuted))
            }
            .foregroundStyle(Color(NestColor.textSecondary))
            .frame(maxWidth: .infinity, minHeight: NestSpace.s10 + NestSpace.s8)
            .overlay {
                shape.strokeBorder(Color(isDropping ? NestColor.clay : NestColor.lineStrong),
                                   style: StrokeStyle(lineWidth: hairline * 2, dash: [NestSpace.s1, NestSpace.s1]))
            }
            .contentShape(shape)
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier("swift.launcher.add")
    }

    private func open(_ id: String) {
        Task { await session.open(id) }
        close()
    }

    private func pick() {
        let panel = NSOpenPanel()
        panel.canChooseDirectories = true
        panel.canChooseFiles = false
        panel.allowsMultipleSelection = false
        panel.prompt = "Open in Swift"
        panel.message = "Choose a project folder for Claude Code."
        guard panel.runModal() == .OK, let url = panel.url else { return }
        add(url)
    }

    private func add(_ url: URL) {
        Task {
            await session.page.addProject(at: url)
            if session.page.project.url.standardizedFileURL == url.standardizedFileURL {
                await session.open(session.page.selected)
                close()
            }
        }
    }
}
