import NestKit
import SwiftUI

/// Every bird's tag at the point the scene gives it.
struct FlockTags: View {
    let tags: SceneTags
    let statuses: [Bird: BirdStatus]

    var body: some View {
        ZStack {
            Color.clear
            ForEach(Bird.allCases, id: \.self) { bird in
                if let point = tags.points[bird] {
                    FlockTag(bird: bird, status: statuses[bird] ?? .asleep)
                        .position(point)
                }
            }
        }
        .allowsHitTesting(false)
    }
}
