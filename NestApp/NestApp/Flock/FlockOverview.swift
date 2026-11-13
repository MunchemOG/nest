import NestKit
import SwiftUI

/// Every bird and what it is doing, in flock order.
struct FlockOverview: View {
    let model: FlockModel

    /// The birds shown, in order.
    let birds = Bird.allCases

    var body: some View {
        VStack(alignment: .leading, spacing: NestSpace.s1) {
            ForEach(birds, id: \.self) { bird in
                FlockMemberRow(
                    bird: bird,
                    status: model.status(of: bird),
                    doing: model.state[bird].doing,
                    reactions: model.reactions(of: bird)
                )
            }
        }
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("flock-overview")
    }
}
