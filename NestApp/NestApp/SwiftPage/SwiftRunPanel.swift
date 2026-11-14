import NestKit
import SwiftUI

/// How the chosen project's tasks run: model, effort, subagents; its tests and merging; and its memory.
struct SwiftRunPanel: View {
    let page: SwiftPageModel

    @State private var tests = ""
    @Environment(\.pixelLength) private var hairline

    var body: some View {
        NestPanel(.solid, padding: NestSpace.s4) {
            VStack(alignment: .leading, spacing: NestSpace.s4) {
                SwiftSection("\(page.project.name) runs on") {
                    NestSegmented(options: ClaudeModel.allCases.map { ($0, $0.name) }, selection: page.project.defaults.model,
                                  id: "swift.run.model") { page.setModel($0) }
                    NestSegmented(options: Effort.allCases.map { ($0, $0.name) }, selection: page.project.defaults.effort,
                                  id: "swift.run.effort") { page.setEffort($0) }
                    toggle("Subagents", isOn: page.project.defaults.subagents, id: "swift.run.subagents") { page.setSubagents($0) }
                }
                SwiftSection("Tests") {
                    TextField("No tests: work waits on its branch for you", text: $tests)
                        .textFieldStyle(.plain)
                        .nestFont(.code)
                        .foregroundStyle(Color(NestColor.textPrimary))
                        .padding(.horizontal, NestSpace.s3)
                        .padding(.vertical, NestSpace.s1)
                        .background { Capsule().fill(Color(NestColor.line)) }
                        .overlay { Capsule().strokeBorder(Color(NestColor.line), lineWidth: hairline) }
                        .onSubmit { page.setTests(tests) }
                        .accessibilityIdentifier("swift.run.tests")
                    toggle("Merge green work by itself", isOn: page.project.autoMerge, id: "swift.run.merge") { page.setAutoMerge($0) }
                        .disabled(page.project.tests == nil)
                }
                SwiftSection("Memory · .nest/memory") {
                    HStack(alignment: .firstTextBaseline, spacing: NestSpace.s2) {
                        Text(page.memoryLine)
                            .nestFont(.bodyS)
                            .foregroundStyle(Color(NestColor.textSecondary))
                            .fixedSize(horizontal: false, vertical: true)
                            .accessibilityIdentifier("swift.memory.line")
                        Spacer(minLength: NestSpace.s2)
                        Button("Rebuild") { Task { await page.rebuildMemory() } }
                            .buttonStyle(NestButtonStyle(.secondary, size: .small))
                            .accessibilityIdentifier("swift.memory.rebuild")
                    }
                    Menu {
                        ForEach(ClaudeModel.allCases, id: \.self) { model in
                            Button(model.name) { page.setMemoryModel(model) }
                        }
                    } label: {
                        Text("Built on \(page.project.memory.label)")
                            .nestFont(.caption)
                            .foregroundStyle(Color(NestColor.textMuted))
                    }
                    .menuStyle(.borderlessButton)
                    .fixedSize()
                    .accessibilityIdentifier("swift.memory.model")
                }
            }
        }
        .onAppear { tests = page.testsLine }
        .onChange(of: page.selected) { tests = page.testsLine }
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("swift.run")
    }

    private func toggle(_ title: String, isOn: Bool, id: String, set: @escaping (Bool) -> Void) -> some View {
        Toggle(isOn: Binding(get: { isOn }, set: set)) {
            Text(title)
                .nestFont(.bodyS)
                .foregroundStyle(Color(NestColor.textSecondary))
        }
        .toggleStyle(.switch)
        .controlSize(.small)
        .tint(Color(NestColor.clay))
        .accessibilityIdentifier(id)
    }
}
