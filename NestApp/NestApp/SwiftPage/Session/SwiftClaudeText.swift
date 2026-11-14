import NestKit
import SwiftUI

/// What Claude said, as plain prose with its inline formatting; a soft dot follows it while it is still writing.
struct SwiftClaudeText: View {
    let text: String
    let isStreaming: Bool

    var body: some View {
        let options = AttributedString.MarkdownParsingOptions(interpretedSyntax: .inlineOnlyPreservingWhitespace)
        HStack(alignment: .lastTextBaseline, spacing: NestSpace.s1) {
            Text((try? AttributedString(markdown: text, options: options)) ?? AttributedString(text))
                .nestFont(.body)
                .foregroundStyle(Color(NestColor.textPrimary))
                .textSelection(.enabled)
                .fixedSize(horizontal: false, vertical: true)
            if isStreaming {
                Circle().fill(Color(Bird.swift.color)).frame(width: NestSpace.s2, height: NestSpace.s2)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
