import NestKit
import SwiftUI

/// Setting up scheduled work, all by picking: the project, what to ask, the model and effort, Ultracode,
/// how freely Claude Code may act, and when it runs.
struct SwiftScheduleSheet: View {
    let page: SwiftPageModel
    @State var draft: SwiftScheduleDraft
    let close: () -> Void

    @Environment(\.pixelLength) private var hairline

    var body: some View {
        VStack(alignment: .leading, spacing: NestSpace.s4) {
            HStack {
                Text("Schedule work")
                    .nestFont(.title)
                    .foregroundStyle(Color(NestColor.textPrimary))
                Spacer()
                Button("Cancel", action: close)
                    .buttonStyle(NestButtonStyle(.quiet, size: .small))
                    .keyboardShortcut(.cancelAction)
                Button("Schedule") {
                    page.addJob(draft.job())
                    close()
                }
                .buttonStyle(NestButtonStyle(.solid, size: .small))
                .disabled(!draft.isReady)
                .accessibilityIdentifier("swift.schedule.save")
            }
            Menu {
                ForEach(page.projects) { project in
                    Button(project.name) { draft.project = project.id }
                }
            } label: {
                HStack(spacing: NestSpace.s2) {
                    if let project = page.projects.first(where: { $0.id == draft.project }) {
                        SwiftProjectTileView(project: project, size: NestSpace.s6)
                        Text(project.name).nestFont(.title).foregroundStyle(Color(NestColor.textPrimary))
                    }
                    Image(systemName: "chevron.down").font(.nest(.caption)).foregroundStyle(Color(NestColor.textMuted))
                }
            }
            .menuStyle(.borderlessButton).menuIndicator(.hidden).fixedSize()
            TextField("What should Claude Code do?", text: $draft.prompt, axis: .vertical)
                .textFieldStyle(.plain)
                .nestFont(.body)
                .lineLimit(3...8)
                .padding(NestSpace.s3)
                .background { RoundedRectangle(cornerRadius: NestRadius.md).fill(Color(NestColor.line)) }
                .accessibilityIdentifier("swift.schedule.prompt")
            NestSegmented(options: ClaudeModel.allCases.map { (value: $0, title: $0.name) }, selection: draft.settings.model,
                          id: "swift.schedule.model") { draft.settings.model = $0 }
            NestSegmented(options: Effort.allCases.map { (value: $0, title: $0.name) }, selection: draft.settings.effort,
                          id: "swift.schedule.effort") { draft.settings.effort = $0 }
            HStack(spacing: NestSpace.s3) {
                Toggle("Ultracode", isOn: $draft.ultracode)
                    .toggleStyle(.switch).controlSize(.small).tint(Color(NestColor.clay))
                    .nestFont(.label)
                NestSegmented(options: [(value: PermissionMode.acceptEdits, title: "Accept edits"), (value: .plan, title: "Plan"),
                                        (value: .auto, title: "Auto")],
                              selection: draft.mode, id: "swift.schedule.mode") { draft.mode = $0 }
            }
            Text(draft.mode == .auto ? "Auto never asks: Claude Code can run any command in its own worktree."
                 : "You're away, so anything Claude Code would ask about is refused.")
                .nestFont(.caption)
                .foregroundStyle(Color(NestColor.textMuted))
            whenPicker
        }
        .padding(NestSpace.s5)
        .frame(width: HomeLayout.session)
        .background(Color(NestColor.surface2))
    }

    private var whenPicker: some View {
        VStack(alignment: .leading, spacing: NestSpace.s2) {
            Text("When").nestFont(.caption).foregroundStyle(Color(NestColor.textMuted))
            HStack(spacing: NestSpace.s2) {
                ForEach(SwiftScheduleDraft.When.allCases, id: \.self) { when in
                    whenCard(when)
                }
            }
            switch draft.when {
            case .at:
                DatePicker("Run at", selection: $draft.date, in: Date.now...).nestFont(.bodyS)
            case .nightly:
                Stepper("From \(String(format: "%02d:00", draft.hour)), in a gap", value: $draft.hour, in: 0...23).nestFont(.bodyS)
            case .weekly:
                HStack {
                    Picker("Day", selection: $draft.weekday) {
                        ForEach(1...7, id: \.self) { Text(Calendar.current.weekdaySymbols[$0 - 1]).tag($0) }
                    }
                    .fixedSize()
                    Stepper("from \(String(format: "%02d:00", draft.hour))", value: $draft.hour, in: 0...23)
                }
                .nestFont(.bodyS)
            default:
                EmptyView()
            }
        }
    }

    private func whenCard(_ when: SwiftScheduleDraft.When) -> some View {
        let isOn = draft.when == when
        let shape = RoundedRectangle(cornerRadius: NestRadius.md, style: .continuous)
        return Button { draft.when = when } label: {
            VStack(alignment: .leading, spacing: NestSpace.s1 / 2) {
                Text(when.title).nestFont(.label).foregroundStyle(Color(NestColor.textPrimary))
                Text(hint(when)).nestFont(.caption).foregroundStyle(Color(NestColor.textMuted)).lineLimit(1)
            }
            .padding(NestSpace.s2)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background { shape.fill(Color(isOn ? NestColor.lineStrong : NestColor.line)) }
            .overlay { shape.strokeBorder(Color(isOn ? NestColor.textPrimary : NestColor.line), lineWidth: hairline) }
            .contentShape(shape)
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier("swift.schedule.when.\(when.rawValue)")
    }

    private func hint(_ when: SwiftScheduleDraft.When) -> String {
        var job = draft.job()
        switch when {
        case .nextGap: job.timing = .nextGap
        case .tonight: job.timing = .tonight
        default: return when == .at ? "pick a time" : "repeats"
        }
        return page.whenLine(job)
    }
}
