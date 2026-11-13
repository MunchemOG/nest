import NestKit
import SwiftUI

/// The pill you type into, with a send button that wakes up once there is something to send.
struct ChatComposer: View {
    @Binding var draft: ChatDraft
    let placeholder: String
    let onSend: (String) -> Void

    @Environment(\.pixelLength) private var hairline

    var body: some View {
        HStack(spacing: NestSpace.s2) {
            TextField(placeholder, text: $draft.text, prompt: Text(placeholder).foregroundStyle(Color(NestColor.textMuted)))
                .textFieldStyle(.plain)
                .nestFont(.body)
                .foregroundStyle(Color(NestColor.textPrimary))
                .onSubmit(send)
            Button(action: send) {
                Image(systemName: "arrow.up")
                    .font(.nest(.label))
                    .accessibilityLabel("Send")
            }
            .buttonStyle(SendButtonStyle())
            .disabled(!draft.canSend)
        }
        .padding(.leading, NestSpace.s5)
        .padding(.trailing, NestSpace.s1)
        .padding(.vertical, NestSpace.s1)
        .background { Capsule().fill(Color(NestColor.glassBar)) }
        .overlay { Capsule().strokeBorder(Color(NestColor.line), lineWidth: hairline) }
        .nestShadow(.bar, in: Capsule())
    }

    private func send() {
        if let text = draft.send() { onSend(text) }
    }
}
