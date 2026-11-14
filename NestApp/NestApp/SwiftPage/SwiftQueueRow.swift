import NestKit
import SwiftUI

/// One queued task: its id and goal, and a chip that says how it runs; the chip opens a menu to run it differently.
struct SwiftQueueRow: View {
    let task: QueuedTask
    let defaults: RunSettings
    let setRun: (RunSettings?) -> Void

    @Environment(\.pixelLength) private var hairline

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: NestSpace.s2) {
            Text(task.id)
                .nestFont(.label)
                .monospacedDigit()
                .foregroundStyle(Color(task.state == .claimed ? Bird.swift.color : NestColor.textPrimary))
            Text(task.goal)
                .nestFont(.bodyS)
                .foregroundStyle(Color(NestColor.textSecondary))
                .lineLimit(2)
                .frame(maxWidth: .infinity, alignment: .leading)
            Menu {
                Button("Use the project's default (\(defaults.label))") { setRun(nil) }
                Section("Model") {
                    ForEach(ClaudeModel.allCases, id: \.self) { model in
                        Button(model.name) { setRun(with { $0.model = model }) }
                    }
                }
                Section("Effort") {
                    ForEach(Effort.allCases, id: \.self) { effort in
                        Button(effort.name) { setRun(with { $0.effort = effort }) }
                    }
                }
                Button(current.subagents ? "Keep it in one session" : "Let it use subagents") {
                    setRun(with { $0.subagents.toggle() })
                }
            } label: {
                Text(task.state == .claimed ? "Building" : (task.run?.label ?? "Default"))
                    .nestFont(.caption)
                    .foregroundStyle(Color(task.run == nil ? NestColor.textMuted : NestColor.textPrimary))
                    .padding(.horizontal, NestSpace.s2)
                    .padding(.vertical, NestSpace.s1 / 2)
                    .background { Capsule().fill(Color(task.run == nil ? NestColor.line : Bird.swift.tint)) }
            }
            .menuStyle(.borderlessButton)
            .menuIndicator(.hidden)
            .fixedSize()
            .disabled(task.state == .claimed)
            .accessibilityIdentifier("swift.queue.run.\(task.id)")
        }
        .padding(.vertical, NestSpace.s2)
        .overlay(alignment: .top) { Rectangle().fill(Color(NestColor.line)).frame(height: hairline) }
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("swift.queue.row")
    }

    private var current: RunSettings { task.run ?? defaults }

    private func with(_ change: (inout RunSettings) -> Void) -> RunSettings {
        var settings = current
        change(&settings)
        return settings
    }
}
