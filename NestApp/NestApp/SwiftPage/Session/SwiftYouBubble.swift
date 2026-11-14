import NestKit
import SwiftUI

/// What you said, on the right, in a glass bubble.
struct SwiftYouBubble: View {
    let text: String

    @Environment(\.pixelLength) private var hairline

    var body: some View {
        HStack {
            Spacer(minLength: NestSpace.s8)
            Text(text)
                .nestFont(.body)
                .foregroundStyle(Color(NestColor.textPrimary))
                .textSelection(.enabled)
                .padding(.horizontal, NestSpace.s4)
                .padding(.vertical, NestSpace.s2)
                .background { RoundedRectangle(cornerRadius: NestRadius.lg, style: .continuous).fill(Color(NestColor.line)) }
                .overlay {
                    RoundedRectangle(cornerRadius: NestRadius.lg, style: .continuous)
                        .strokeBorder(Color(NestColor.line), lineWidth: hairline)
                }
        }
    }
}
