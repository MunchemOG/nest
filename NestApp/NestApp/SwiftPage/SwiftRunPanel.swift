import NestKit
import SwiftUI

/// How the chosen project's tasks run: model, effort, subagents; its tests and merging.
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
