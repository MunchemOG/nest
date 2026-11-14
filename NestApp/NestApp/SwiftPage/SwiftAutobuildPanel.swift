import NestKit
import SwiftUI

/// The Nest's autobuild: what it builds next once you're away, the model it builds on, and a field to add a task.
struct SwiftAutobuildPanel: View {
    let page: SwiftPageModel

    @State private var draft = ChatDraft()

    var body: some View {
        NestPanel(.solid, padding: NestSpace.s4) {
            VStack(alignment: .leading, spacing: NestSpace.s3) {
                HStack {
                    Text("Nest autobuild")
                        .nestFont(.title)
                        .foregroundStyle(Color(NestColor.textPrimary))
                    Spacer()
                    StatusPill(.bird(.swift, page.autobuild.contains { $0.state == .claimed } ? .active : .resting))
                }
                Text(page.autobuild.isEmpty ? "Nothing waiting in docs/queue.md." :
                        "Builds docs/queue.md once you're away. Next: \(page.autobuild[0].id)"
                        + (page.autobuild.count > 1 ? " and \(page.autobuild.count - 1) more." : "."))
                    .nestFont(.bodyS)
                    .foregroundStyle(Color(NestColor.textSecondary))
                    .fixedSize(horizontal: false, vertical: true)
                if let nest = page.nest {
                    NestSegmented(options: ClaudeModel.allCases.map { ($0, $0.name) }, selection: nest.defaults.model,
                                  id: "swift.autobuild.model") { page.setAutobuildModel($0) }
                    NestSegmented(options: Effort.allCases.map { ($0, $0.name) }, selection: nest.defaults.effort,
                                  id: "swift.autobuild.effort") { page.setAutobuildEffort($0) }
                }
                ChatComposer(draft: $draft, placeholder: "Add a task: … Done means: …") { text in
                    Task { await page.queueForNest(text) }
                }
                .accessibilityIdentifier("swift.autobuild.add")
                if let reply = page.messages.last, reply.sender == .bird(.swift) {
                    Text(reply.text)
                        .nestFont(.caption)
                        .foregroundStyle(Color(NestColor.textMuted))
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("swift.autobuild")
    }
}
