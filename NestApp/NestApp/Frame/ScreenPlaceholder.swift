import NestKit
import SwiftUI

/// A screen that has its place in the frame but no content yet.
struct ScreenPlaceholder: View {
    let screen: NestScreen

    var body: some View {
        Text(screen.title)
            .nestFont(.displayL)
            .foregroundStyle(Color(NestColor.textPrimary))
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            .accessibilityElement(children: .contain)
            .accessibilityIdentifier(screen.screenID)
    }
}
