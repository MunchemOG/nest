import NestKit
import SwiftUI

/// Claude Code asking before it acts, exactly as in the terminal: what it wants to do, then Allow, Always allow or Deny.
struct SwiftPermissionCard: View {
    let permission: TranscriptItem.Permission
    let answer: (PermissionAnswer) -> Void

    @Environment(\.pixelLength) private var hairline

    var body: some View {
        let shape = RoundedRectangle(cornerRadius: NestRadius.lg, style: .continuous)
        VStack(alignment: .leading, spacing: NestSpace.s3) {
            HStack(spacing: NestSpace.s2) {
                Circle().fill(Color(NestColor.clay)).frame(width: NestSpace.s2, height: NestSpace.s2)
                Text(heading)
                    .nestFont(.label)
                    .foregroundStyle(Color(NestColor.textPrimary))
            }
            Text(permission.request.summary)
                .nestFont(.code)
                .foregroundStyle(Color(NestColor.textPrimary))
                .textSelection(.enabled)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(NestSpace.s3)
                .background { RoundedRectangle(cornerRadius: NestRadius.sm).fill(Color(NestColor.surface0)) }
            if let given = permission.answer {
                Text(given == .deny ? "You denied this." : given == .allowAlways ? "Allowed, and won't ask again." : "Allowed.")
                    .nestFont(.caption)
                    .foregroundStyle(Color(NestColor.textMuted))
            } else {
                HStack(spacing: NestSpace.s2) {
                    Button("Allow") { answer(.allow) }
                        .buttonStyle(NestButtonStyle(.solid, size: .small))
                        .keyboardShortcut(.defaultAction)
                        .accessibilityIdentifier("swift.permission.allow")
                    if !permission.request.suggestions.isEmpty {
                        Button("Always allow") { answer(.allowAlways) }
                            .buttonStyle(NestButtonStyle(.secondary, size: .small))
                            .accessibilityIdentifier("swift.permission.always")
                    }
                    Button("Deny") { answer(.deny) }
                        .buttonStyle(NestButtonStyle(.secondary, size: .small))
                        .accessibilityIdentifier("swift.permission.deny")
                }
            }
        }
        .padding(NestSpace.s3)
        .background { shape.fill(Color(NestColor.clayTint)) }
        .overlay { shape.strokeBorder(Color(permission.answer == nil ? NestColor.clay : NestColor.line), lineWidth: hairline) }
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("swift.permission")
    }

    private var heading: String {
        switch permission.request.tool {
        case "Bash": "Claude wants to run a command"
        case "Edit", "Write", "MultiEdit", "NotebookEdit": "Claude wants to change a file"
        case "WebFetch", "WebSearch": "Claude wants to go online"
        default: "Claude wants to use \(permission.request.tool)"
        }
    }
}
