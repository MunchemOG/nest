import NestKit
import SwiftUI

/// One project in the launcher: its tile, name and folder, where its repository stands, and two weeks of your work in it.
struct SwiftProjectCard: View {
    let project: SwiftProject
    let history: ClaudeHistory
    let isCurrent: Bool
    let shortcut: Int?
    let open: () -> Void

    @State private var status: ProjectStatus?
    @State private var activity: [Int] = Array(repeating: 0, count: 14)
    @State private var isHovered = false
    @Environment(\.pixelLength) private var hairline

    var body: some View {
        let shape = RoundedRectangle(cornerRadius: NestRadius.xl, style: .continuous)
        Button(action: open) {
            VStack(alignment: .leading, spacing: NestSpace.s2) {
                HStack(alignment: .top) {
                    SwiftProjectTileView(project: project, size: NestSpace.s7)
                    Spacer()
                    if let shortcut { chip("⌘\(shortcut)") }
                }
                Text(project.name)
                    .nestFont(.title)
                    .foregroundStyle(Color(NestColor.textPrimary))
                    .lineLimit(1)
                Text(project.folder.replacingOccurrences(of: NSHomeDirectory(), with: "~"))
                    .nestFont(.caption)
                    .foregroundStyle(Color(NestColor.textMuted))
                    .lineLimit(1)
                    .truncationMode(.middle)
                HStack(spacing: NestSpace.s1) {
                    if let status {
                        if let branch = status.branch {
                            chip(branch)
                            chip(status.changed == 0 ? "clean" : "\(status.changed) changed")
                        } else {
                            chip("no git")
                        }
                    }
                    if project.importsQueueFile { chip("autobuild") }
                }
                Spacer(minLength: NestSpace.s2)
                SwiftActivityStrip(counts: activity)
            }
            .padding(NestSpace.s4)
            .frame(maxWidth: .infinity, minHeight: NestSpace.s10 + NestSpace.s8, alignment: .topLeading)
            .background { shape.fill(Color(isHovered || isCurrent ? NestColor.lineStrong : NestColor.line)) }
            .overlay { shape.strokeBorder(Color(isCurrent ? NestColor.textPrimary : NestColor.line), lineWidth: hairline) }
            .contentShape(shape)
        }
        .buttonStyle(.plain)
        .keyboardShortcut(KeyEquivalent(Character(String(shortcut ?? 0))), modifiers: shortcut == nil ? [.command, .control, .option] : .command)
        .onHover { isHovered = $0 }
        .task {
            let folder = project.url
            status = await ProjectStatus.read(folder)
            let history = history
            activity = await Task.detached { history.activity(in: folder, days: 14, until: .now) }.value
        }
        .accessibilityIdentifier("swift.launcher.\(project.id)")
    }

    private func chip(_ text: String) -> some View {
        Text(text)
            .nestFont(.caption)
            .foregroundStyle(Color(NestColor.textSecondary))
            .lineLimit(1)
            .padding(.horizontal, NestSpace.s2)
            .padding(.vertical, NestSpace.s1 / 2)
            .background { Capsule().fill(Color(NestColor.line)) }
    }
}
