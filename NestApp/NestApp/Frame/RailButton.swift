import NestKit
import SwiftUI

/// One square button on the rail; the selected one carries a clay marker on the rail's edge.
struct RailButton: View {
    let screen: NestScreen
    let isSelected: Bool
    let select: () -> Void

    @State private var isHovered = false
    @Environment(\.nestAccent) private var accent

    /// The button's width and height.
    static let side = NestSpace.s6 + NestSpace.s2

    var body: some View {
        let palette = RailButtonPalette(isSelected: isSelected, isHovered: isHovered, accent: accent)
        let shape = RoundedRectangle(cornerRadius: NestRadius.md, style: .continuous)
        Button(action: select) {
            Image(systemName: screen.symbol)
                .font(.nest(.title))
                .foregroundStyle(Color(palette.icon))
                .frame(width: Self.side, height: Self.side)
                .background { shape.fill(palette.fill.map { Color($0) } ?? .clear) }
                .contentShape(shape)
        }
        .buttonStyle(.plain)
        .focusEffectDisabled()
        .overlay(alignment: .leading) {
            if let marker = palette.marker {
                Capsule()
                    .fill(Color(marker))
                    .frame(width: NestSpace.s1, height: Self.side - 2 * NestSpace.s3)
                    .offset(x: -NestSpace.s2)
            }
        }
        .onHover { isHovered = $0 }
        .animation(.nest(NestMotion.fast), value: palette)
        .help(screen.title)
        .accessibilityLabel(screen.title)
        .accessibilityIdentifier(screen.railID)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}
