import NestKit
import SwiftUI

/// Every bird's tag at the point the scene gives it.
struct FlockTags: View {
    let tags: SceneTags
    let statuses: [Bird: BirdStatus]
    let line: (Bird) -> String

    var body: some View {
        ZStack {
            Color.clear
            ForEach(Bird.allCases, id: \.self) { bird in
                if let point = tags.points[bird] {
                    FlockTag(bird: bird, status: statuses[bird] ?? .asleep, line: line(bird))
                        .position(point)
                }
            }
        }
        .allowsHitTesting(false)
    }
}
