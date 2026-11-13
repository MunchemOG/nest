import NestKit
import SwiftUI

/// One message: a bird's on the left with its mini tile, yours on the right.
struct ChatBubble: View {
    let message: ChatMessage

    init(_ message: ChatMessage) {
        self.message = message
    }

    var body: some View {
        HStack(alignment: .top, spacing: NestSpace.s3) {
            if message.sender.alignment == .trailing { Spacer(minLength: NestSpace.s7) }
            if let bird = message.sender.bird { BirdAvatar(bird) }
            Text(message.text)
                .nestFont(.body)
                .foregroundStyle(Color(NestColor.textPrimary))
                .fixedSize(horizontal: false, vertical: true)
                .chatBubble(message.sender.fill)
            if message.sender.alignment == .leading { Spacer(minLength: NestSpace.s7) }
        }
        .accessibilityElement(children: .combine)
    }
}
