import AppKit
import NestKit
import SwiftUI

/// Your projects as pills; the one you're talking about is white. The plus opens a folder picker to add one.
struct SwiftProjectPills: View {
    let page: SwiftPageModel

    @Environment(\.pixelLength) private var hairline

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: NestSpace.s2) {
                ForEach(page.projects) { project in
                    let isOn = project.id == page.selected
                    Button { Task { await page.select(project.id) } } label: {
                        Text(project.name)
                            .nestFont(.label)
                            .foregroundStyle(Color(isOn ? NestColor.surface0 : NestColor.textPrimary))
                            .padding(.horizontal, NestSpace.s3)
                            .padding(.vertical, NestSpace.s1)
                            .background { Capsule().fill(Color(isOn ? NestColor.textPrimary : NestColor.line)) }
                            .overlay { Capsule().strokeBorder(Color(NestColor.lineStrong), lineWidth: isOn ? 0 : hairline) }
                            .contentShape(Capsule())
                    }
                    .buttonStyle(.plain)
                    .accessibilityAddTraits(isOn ? .isSelected : [])
                    .accessibilityIdentifier("swift.project.\(project.id)")
                }
                Button(action: pick) {
                    Image(systemName: "plus")
                        .font(.nest(.label))
                        .foregroundStyle(Color(NestColor.textPrimary))
                        .frame(width: NestFont.label.lineHeight + NestSpace.s2, height: NestFont.label.lineHeight + NestSpace.s2)
                        .overlay { Capsule().strokeBorder(Color(NestColor.lineStrong), lineWidth: hairline) }
                        .contentShape(Capsule())
                }
                .buttonStyle(.plain)
                .help("Add a project folder")
                .accessibilityLabel("Add a project")
                .accessibilityIdentifier("swift.project.add")
            }
        }
    }

    private func pick() {
        let panel = NSOpenPanel()
        panel.canChooseDirectories = true
        panel.canChooseFiles = false
        panel.allowsMultipleSelection = false
        panel.prompt = "Give to Swift"
        panel.message = "Choose a project folder (a git repository) for Swift to work in."
        guard panel.runModal() == .OK, let url = panel.url else { return }
        Task { await page.addProject(at: url) }
    }
}
