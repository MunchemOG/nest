import NestKit
import SwiftUI

/// Home: the headline, the live activity feed, what needs you, and every bird at a glance.
struct HomeScreen: View {
    let model: HomeModel

    var body: some View {
        HStack(alignment: .top, spacing: NestSpace.s6) {
            VStack(alignment: .leading, spacing: NestSpace.s6) {
                HeadlineView(headline: model.headline)
                Spacer(minLength: NestSpace.s6)
                ActivityFeed(model: model)
                    .frame(width: HomeLayout.column)
            }
            Spacer(minLength: 0)
            ScrollView {
                VStack(alignment: .leading, spacing: NestSpace.s3) {
                    NeedsYouStack(events: model.needsYou)
                    NestPanel(.solid, padding: NestSpace.s2) {
                        FlockOverview(model: model.flock)
                    }
                }
            }
            .scrollIndicators(.never)
            .frame(width: HomeLayout.column)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier(NestScreen.home.screenID)
    }
}
