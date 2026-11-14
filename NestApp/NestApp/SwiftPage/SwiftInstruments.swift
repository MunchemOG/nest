import NestKit
import SwiftUI

/// The right of Swift's cockpit: your limits above, how the chosen project runs below.
struct SwiftInstruments: View {
    let page: SwiftPageModel

    var body: some View {
        VStack(spacing: NestSpace.s3) {
            SwiftLimitsPanel(page: page)
            SwiftRunPanel(page: page)
        }
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("swift.instruments")
    }
}
