import NestKit
import SwiftUI

/// Where you talk to Claude Code: what you type, Claude Code's slash commands as you type a slash, and below it the model,
/// effort, Ultracode, how it asks, what the session has cost, and send or stop.
struct SwiftComposer: View {
    @Bindable var session: SwiftSessionModel
    let compact: Bool

    @State private var scheduling: SwiftScheduleDraft?
    @FocusState private var focused: Bool
    @Environment(\.pixelLength) private var hairline

    var body: some View {
        let shape = RoundedRectangle(cornerRadius: NestRadius.xl, style: .continuous)
        VStack(alignment: .leading, spacing: NestSpace.s2) {
            suggestionList
            field
            controls
        }
        .padding(.leading, NestSpace.s4)
        .padding(.trailing, NestSpace.s2)
        .padding(.vertical, NestSpace.s3)
        .background { shape.fill(Color(NestColor.glassBar)) }
        .overlay { shape.strokeBorder(Color(focused ? NestColor.lineStrong : NestColor.line), lineWidth: hairline) }
        .nestShadow(.bar, in: shape)
        .onAppear { focused = true }
        .sheet(item: $scheduling) { draft in
            SwiftScheduleSheet(page: session.page, draft: draft) { scheduling = nil }
        }
    }

    @ViewBuilder
    private var suggestionList: some View {
        let suggestions = session.suggestions(for: session.draft)
        if !suggestions.isEmpty {
            VStack(alignment: .leading, spacing: 0) {
                ForEach(suggestions.prefix(6), id: \.name) { command in
                    Button { session.draft = "/\(command.name) " } label: {
                        HStack(spacing: NestSpace.s2) {
                            Text("/\(command.name)").nestFont(.code).foregroundStyle(Color(NestColor.textPrimary))
                            Text(command.description).nestFont(.caption).foregroundStyle(Color(NestColor.textMuted)).lineLimit(1)
                            Spacer(minLength: 0)
                        }
                        .padding(.vertical, NestSpace.s1)
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private var field: some View {
        TextField(session.isWorking ? "Claude is working… type to queue your next message" : "Reply to Claude, or type / for commands…",
                  text: $session.draft, axis: .vertical)
            .textFieldStyle(.plain)
            .nestFont(.body)
            .foregroundStyle(Color(NestColor.textPrimary))
            .lineLimit(1...(compact ? 4 : 8))
            .focused($focused)
            .onSubmit(send)
            .onKeyPress(.escape) {
                guard session.isWorking else { return .ignored }
                stop()
                return .handled
            }
            .accessibilityIdentifier("swift.composer")
    }

    private var stopping: Bool { session.isWorking && session.draft.isEmpty }

    private var controls: some View {
        HStack(spacing: NestSpace.s2) {
            modelPicker
            if !compact {
                effortMenu
                ultracodeSwitch
                modeMenu
            }
            Spacer(minLength: NestSpace.s2)
            if !compact {
                Button { scheduling = draft } label: {
                    Image(systemName: "clock").font(.nest(.label)).foregroundStyle(Color(NestColor.textSecondary))
                }
                .buttonStyle(.plain)
                .help("Schedule this for when you're away")
                .accessibilityIdentifier("swift.schedule")
            }
            if !compact, let lines = session.page.claude, lines.linesAdded + lines.linesRemoved > 0 {
                Text("+\(lines.linesAdded) −\(lines.linesRemoved)")
                    .nestFont(.caption)
                    .monospacedDigit()
                    .foregroundStyle(Color(NestColor.textMuted))
                    .help("Lines this session changed")
            }
            if let context = session.contextLine {
                Text(context)
                    .nestFont(.caption)
                    .monospacedDigit()
                    .foregroundStyle(Color(NestColor.textMuted))
                    .help("How full Claude's context is; Claude Code compacts it when it fills")
                    .accessibilityIdentifier("swift.context")
            }
            if session.transcript.costUSD > 0 {
                Text(String(format: "$%.2f", session.transcript.costUSD))
                    .nestFont(.caption)
                    .monospacedDigit()
                    .foregroundStyle(Color(NestColor.textMuted))
            }
            Button { if stopping { stop() } else { send() } } label: {
                Image(systemName: stopping ? "stop.fill" : "arrow.up")
                    .font(.nest(.label))
                    .accessibilityLabel(stopping ? "Stop" : "Send")
            }
            .buttonStyle(SendButtonStyle())
            .disabled(!session.isWorking && session.draft.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            .accessibilityIdentifier("swift.send")
        }
    }

    private var modelPicker: some View {
        NestSegmented(options: Self.models, selection: session.model, id: "swift.model") { model in
            Task { await session.setModel(model) }
        }
        .fixedSize()
    }

    private static let models: [(value: ClaudeModel, title: String)] = ClaudeModel.allCases.map { (value: $0, title: $0.name) }

    private var effortMenu: some View {
        Menu {
            ForEach(Effort.allCases, id: \.self) { effort in
                Button(effort.name) { session.effort = effort }
            }
        } label: { pill("\(session.effort.name) effort") }
        .menuStyle(.borderlessButton).menuIndicator(.hidden).fixedSize()
        .accessibilityIdentifier("swift.effort")
    }

    private var modeMenu: some View {
        Menu {
            ForEach(PermissionMode.allCases, id: \.self) { mode in
                Button(mode.name) { Task { await session.setMode(mode) } }
            }
        } label: { pill(session.mode?.name ?? "Ask") }
        .menuStyle(.borderlessButton).menuIndicator(.hidden).fixedSize()
        .accessibilityIdentifier("swift.mode")
    }

    private var ultracodeSwitch: some View {
        Button { session.ultracode.toggle() } label: {
            HStack(spacing: NestSpace.s1) {
                Image(systemName: session.ultracode ? "point.3.filled.connected.trianglepath.dotted" : "point.3.connected.trianglepath.dotted")
                    .font(.nest(.caption))
                Text("Ultracode").nestFont(.label).lineLimit(1)
            }
            .fixedSize()
            .foregroundStyle(Color(session.ultracode ? NestColor.onClay : NestColor.textSecondary))
            .padding(.horizontal, NestSpace.s3)
            .padding(.vertical, NestSpace.s1)
            .background { Capsule().fill(Color(session.ultracode ? NestColor.clay : NestColor.line)) }
            .contentShape(Capsule())
        }
        .buttonStyle(.plain)
        .help("Run your next message as Claude Code's multi-agent Ultracode")
        .accessibilityAddTraits(session.ultracode ? .isSelected : [])
        .accessibilityIdentifier("swift.ultracode")
    }

    private func pill(_ title: String) -> some View {
        HStack(spacing: NestSpace.s1) {
            Text(title).nestFont(.label)
            Image(systemName: "chevron.down").font(.nest(.caption))
        }
        .foregroundStyle(Color(NestColor.textSecondary))
        .padding(.horizontal, NestSpace.s3)
        .padding(.vertical, NestSpace.s1)
        .background { Capsule().fill(Color(NestColor.line)) }
    }

    private var draft: SwiftScheduleDraft {
        SwiftScheduleDraft(project: session.projectID, prompt: session.draft,
                           settings: RunSettings(model: session.model, effort: session.effort, subagents: false),
                           ultracode: session.ultracode, date: .now.addingTimeInterval(3600))
    }

    private func send() {
        let message = session.draft
        session.draft = ""
        Task { await session.send(message) }
    }

    private func stop() {
        Task { await session.interrupt() }
    }
}
