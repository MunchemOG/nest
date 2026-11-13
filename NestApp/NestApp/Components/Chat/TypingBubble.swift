import NestKit
import SwiftUI

/// A bird's bubble holding typing dots while it writes.
struct TypingBubble: View {
    let bird: Bird

    init(_ bird: Bird) {
        self.bird = bird
    }

    var body: some View {
        HStack(alignment: .top, spacing: NestSpace.s3) {
            BirdAvatar(bird)
            TypingDots()
                .frame(height: NestFont.body.lineHeight)
                .chatBubble(bird.tint)
            Spacer(minLength: NestSpace.s7)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(bird.name) is writing")
    }
}
