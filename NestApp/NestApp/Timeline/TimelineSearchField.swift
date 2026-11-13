import NestKit
import SwiftUI

/// The pill you type into to search the timeline.
struct TimelineSearchField: View {
    @Binding var text: String

    @Environment(\.pixelLength) private var hairline

    var body: some View {
        HStack(spacing: NestSpace.s2) {
            Image(systemName: "magnifyingglass")
                .font(.nest(.bodyS))
                .foregroundStyle(Color(NestColor.textMuted))
                .accessibilityHidden(true)
            TextField("Search", text: $text, prompt: Text("Search files, birds, anything").foregroundStyle(Color(NestColor.textMuted)))
                .textFieldStyle(.plain)
                .nestFont(.body)
                .foregroundStyle(Color(NestColor.textPrimary))
                .accessibilityIdentifier("timeline.search")
        }
        .padding(.horizontal, NestSpace.s4)
        .padding(.vertical, NestSpace.s2)
        .background { Capsule().fill(Color(NestColor.surface2)) }
        .overlay { Capsule().strokeBorder(Color(NestColor.line), lineWidth: hairline) }
    }
}
