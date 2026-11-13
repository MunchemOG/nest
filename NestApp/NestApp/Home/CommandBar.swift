import NestKit
import SwiftUI

/// The pill at the bottom of Home: pick a bird (or name one), say what to do, send.
struct CommandBar: View {
    let send: (String, Bird?) -> Void
    var width: Double = NestSpace.s10 * 5

    @State private var draft = ChatDraft()
    @State private var picked: Bird?
    @Environment(\.pixelLength) private var hairline

    var body: some View {
        HStack(spacing: NestSpace.s3) {
            HStack(spacing: NestSpace.s1) {
                ForEach(Bird.allCases, id: \.self) { bird in
                    Button { picked = picked == bird ? nil : bird } label: {
                        BirdAvatar(bird).saturation(picked == nil || picked == bird ? 1 : 0)
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Talk to \(bird.name)")
                    .accessibilityAddTraits(picked == bird ? .isSelected : [])
                }
            }
            Rectangle()
                .fill(Color(NestColor.line))
                .frame(width: hairline, height: NestSpace.s5)
            TextField("Command", text: $draft.text, prompt: Text(prompt).foregroundStyle(Color(NestColor.textMuted)))
                .textFieldStyle(.plain)
                .nestFont(.body)
                .foregroundStyle(Color(NestColor.textPrimary))
                .onSubmit(submit)
                .accessibilityIdentifier("home.command")
            Button(action: submit) {
                Image(systemName: "arrow.up")
                    .font(.nest(.label))
                    .accessibilityLabel("Send")
            }
            .buttonStyle(SendButtonStyle())
            .disabled(!draft.canSend)
        }
        .padding(.leading, NestSpace.s4)
        .padding(.trailing, NestSpace.s2)
        .padding(.vertical, NestSpace.s2)
        .background { Capsule().fill(.ultraThinMaterial) }
        .background { Capsule().fill(Color(NestColor.glassBar)) }
        .overlay { Capsule().strokeBorder(Color(NestColor.line), lineWidth: hairline) }
        .nestShadow(.bar, in: Capsule())
        .frame(width: width)
    }

    private var prompt: String {
        picked.map { "Tell \($0.name) what to do" } ?? "Tell any bird what to do"
    }

    private func submit() {
        guard let text = draft.send() else { return }
        send(text, picked)
    }
}
