import NestKit
import SwiftUI

/// Who wrote a chat message.
enum ChatSender: Hashable, Sendable {
    case bird(Bird)
    case you

    /// The bird, if a bird wrote it.
    var bird: Bird? {
        if case .bird(let bird) = self { bird } else { nil }
    }

    /// The bubble's fill: a bird's tint, or a raised surface for you.
    var fill: NestColor {
        bird?.tint ?? .surface2
    }

    /// Which side the bubble sits on.
    var alignment: HorizontalAlignment {
        bird == nil ? .trailing : .leading
    }
}
