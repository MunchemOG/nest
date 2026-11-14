import NestKit
import SwiftUI

/// The right of Swift's close-up: Swift's week and your scheduled work, your limits, and the Nest's autobuild.
struct SwiftInstruments: View {
    let page: SwiftPageModel

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: NestSpace.s3) {
                SwiftWeekPanel(page: page)
                SwiftLimitsPanel(page: page)
                SwiftAutobuildPanel(page: page)
            }
        }
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("swift.instruments")
    }
}
