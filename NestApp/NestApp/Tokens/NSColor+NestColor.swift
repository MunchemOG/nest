import AppKit
import NestKit

extension NSColor {
    /// An AppKit colour from a colour token.
    convenience init(_ token: NestColor) {
        self.init(
            srgbRed: CGFloat(token.red) / 255,
            green: CGFloat(token.green) / 255,
            blue: CGFloat(token.blue) / 255,
            alpha: CGFloat(token.alpha) / 255
        )
    }
}
