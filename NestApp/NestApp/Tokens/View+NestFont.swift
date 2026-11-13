import NestKit
import SwiftUI

extension Font {
    /// The face and size of a text style token.
    static func nest(_ style: NestFont) -> Font {
        .custom(style.postScriptName, fixedSize: style.size)
    }
}

extension View {
    /// Sets text in a style token: its face, size, letter spacing and line height.
    func nestFont(_ style: NestFont) -> some View {
        font(.nest(style))
            .tracking(style.tracking)
            .lineHeight(.exact(points: style.lineHeight))
    }
}
