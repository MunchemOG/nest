import NestKit
import SwiftUI

/// A titled part of Swift's cockpit: a quiet label, then what it holds.
struct SwiftSection<Content: View>: View {
    let title: String
    let content: Content

    init(_ title: String, @ViewBuilder content: () -> Content) {
        self.title = title
        self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: NestSpace.s2) {
            Text(title)
                .nestFont(.caption)
                .foregroundStyle(Color(NestColor.textMuted))
            content
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
