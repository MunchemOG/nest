import NestKit
import SwiftUI

/// The right of Swift's close-up: your limits above, the Nest's autobuild below.
struct SwiftInstruments: View {
    let page: SwiftPageModel

    var body: some View {
        VStack(spacing: NestSpace.s3) {
            SwiftLimitsPanel(page: page)
            SwiftAutobuildPanel(page: page)
        }
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("swift.instruments")
    }
}
