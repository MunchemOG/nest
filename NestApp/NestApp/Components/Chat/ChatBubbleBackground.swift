import NestKit
import SwiftUI

/// The bubble around a message: a rounded box with the sender's fill.
struct ChatBubbleBackground: ViewModifier {
    let fill: NestColor

    func body(content: Content) -> some View {
        content
            .padding(.horizontal, NestSpace.s4)
            .padding(.vertical, NestSpace.s3)
            .background {
                RoundedRectangle(cornerRadius: NestRadius.lg, style: .continuous).fill(Color(fill))
            }
    }
}

extension View {
    /// Wraps the view in a chat bubble with `fill`.
    func chatBubble(_ fill: NestColor) -> some View {
        modifier(ChatBubbleBackground(fill: fill))
    }
}
