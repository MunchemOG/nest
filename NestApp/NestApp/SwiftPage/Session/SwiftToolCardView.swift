import NestKit
import SwiftUI

/// A tool Claude used: a dot for how it went, the tool, what it touched; open it to see the change and what came back.
struct SwiftToolCardView: View {
    let card: ToolCard

    @State private var isOpen = false
    @Environment(\.pixelLength) private var hairline

    var body: some View {
        let shape = RoundedRectangle(cornerRadius: NestRadius.md, style: .continuous)
        VStack(alignment: .leading, spacing: 0) {
            Button { isOpen.toggle() } label: {
                HStack(spacing: NestSpace.s2) {
                    Circle().fill(Color(dot)).frame(width: NestSpace.s2, height: NestSpace.s2)
                    Text(card.name == "Workflow" ? "Ultracode" : card.name)
                        .nestFont(.label)
                        .foregroundStyle(Color(NestColor.textPrimary))
                    Text(card.summary)
                        .nestFont(.code)
                        .foregroundStyle(Color(NestColor.textSecondary))
                        .lineLimit(1)
                        .truncationMode(.middle)
                    Spacer(minLength: NestSpace.s2)
                    if hasMore {
                        Image(systemName: isOpen ? "chevron.up" : "chevron.down")
                            .font(.nest(.caption))
                            .foregroundStyle(Color(NestColor.textMuted))
                    }
                }
                .padding(.horizontal, NestSpace.s3)
                .padding(.vertical, NestSpace.s2)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .disabled(!hasMore)
            if isOpen {
                Rectangle().fill(Color(NestColor.line)).frame(height: hairline)
                VStack(alignment: .leading, spacing: NestSpace.s2) {
                    if !card.detail.isEmpty { lines(card.detail) }
                    if let result = card.result, !result.isEmpty {
                        Text(result)
                            .nestFont(.code)
                            .foregroundStyle(Color(NestColor.textMuted))
                            .lineLimit(12)
                    }
                }
                .textSelection(.enabled)
                .padding(NestSpace.s3)
            }
        }
        .background { shape.fill(Color(NestColor.surface0)) }
        .overlay { shape.strokeBorder(Color(NestColor.line), lineWidth: hairline) }
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("swift.tool.\(card.id)")
    }

    private var hasMore: Bool { !card.detail.isEmpty || !(card.result ?? "").isEmpty }

    private var dot: NestColor {
        switch card.status {
        case .running: Bird.swift.color
        case .done: .statusSuccess
        case .failed: .statusDanger
        }
    }

    private func lines(_ text: String) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            ForEach(Array(text.split(separator: "\n", omittingEmptySubsequences: false).prefix(40).enumerated()), id: \.offset) { _, line in
                Text(String(line))
                    .nestFont(.code)
                    .foregroundStyle(Color(line.hasPrefix("+ ") ? NestColor.sageSoft
                                           : line.hasPrefix("- ") ? NestColor.claySoft : NestColor.textSecondary))
            }
        }
    }
}
