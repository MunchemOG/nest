import NestKit
import SwiftUI

extension Color {
    /// A SwiftUI colour from a colour token.
    init(_ token: NestColor) {
        self.init(
            .sRGB,
            red: Double(token.red) / 255,
            green: Double(token.green) / 255,
            blue: Double(token.blue) / 255,
            opacity: Double(token.alpha) / 255
        )
    }
}
