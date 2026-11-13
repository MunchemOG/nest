import NestKit
import SwiftUI

/// "All" and one chip per bird; choosing a bird shows only its rows.
struct TimelineFilters: View {
    @Binding var bird: Bird?

    var body: some View {
        HStack(spacing: NestSpace.s2) {
            Button { bird = nil } label: { NestTag("All", isSelected: bird == nil) }
                .buttonStyle(.plain)
                .accessibilityIdentifier("timeline.filter.all")
            ForEach(Bird.allCases, id: \.self) { item in
                Button { bird = bird == item ? nil : item } label: {
                    NestTag(item.name, kind: .bird(item), isSelected: bird == item)
                }
                .buttonStyle(.plain)
                .accessibilityIdentifier("timeline.filter.\(item.rawValue)")
            }
        }
    }
}
