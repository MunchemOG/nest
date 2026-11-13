import NestKit
import SwiftUI

/// A small label chip: a project, a bird, a kind of thing.
struct NestTag: View {
    let title: String
    let kind: NestTagKind
    let isSelected: Bool

    @Environment(\.pixelLength) private var hairline

    init(_ title: String, kind: NestTagKind = .neutral, isSelected: Bool = false) {
        self.title = title
        self.kind = kind
        self.isSelected = isSelected
    }

    var body: some View {
        let shape = RoundedRectangle(cornerRadius: NestRadius.sm, style: .continuous)
        Text(title)
            .nestFont(.caption)
            .lineLimit(1)
            .foregroundStyle(Color(kind.label))
            .padding(.horizontal, NestSpace.s2)
            .padding(.vertical, NestSpace.s1)
            .background { shape.fill(Color(kind.fill)) }
            .overlay { shape.strokeBorder(kind.border(selected: isSelected).map { Color($0) } ?? .clear, lineWidth: hairline) }
            .animation(.nest(NestMotion.base), value: isSelected)
            .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}
