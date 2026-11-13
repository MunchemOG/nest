import NestKit
import SwiftUI

/// The plain statement at the top of Home, with bird names in their own colours.
struct HeadlineView: View {
    let headline: Headline

    @Environment(\.nestAccent) private var accent

    var body: some View {
        VStack(alignment: .leading, spacing: NestSpace.s3) {
            Text(Self.colouringBirdNames(headline.main))
                .nestFont(.displayL)
                .foregroundStyle(Color(NestColor.textPrimary))
                .contentTransition(.opacity)
                .accessibilityLabel(headline.main)
            if !headline.sub.isEmpty || headline.attention != nil {
                (Text(Self.colouringBirdNames(headline.sub)) + Text(attentionText))
                    .nestFont(.bodyL)
                    .foregroundStyle(Color(NestColor.textSecondary))
            }
        }
        .frame(maxWidth: HomeLayout.headline, alignment: .leading)
        .fixedSize(horizontal: false, vertical: true)
        .animation(.nest(NestMotion.slow), value: headline)
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("home.headline")
    }

    private var attentionText: AttributedString {
        guard let attention = headline.attention else { return "" }
        var text = AttributedString((headline.sub.isEmpty ? "" : " ") + attention + " →")
        text.foregroundColor = Color(accent.fill)
        return text
    }

    /// The text with each bird's name in that bird's colour.
    static func colouringBirdNames(_ text: String) -> AttributedString {
        var result = AttributedString(text)
        for bird in Bird.allCases {
            var searchStart = result.startIndex
            while let range = result[searchStart...].range(of: bird.name) {
                result[range].foregroundColor = Color(bird.color)
                searchStart = range.upperBound
            }
        }
        return result
    }
}
