import NestKit
import SwiftUI

/// The smoked-glass rail on the left: the Nest mark, then a button per screen.
struct Rail: View {
    @Binding var selection: NestScreen

    @Environment(\.pixelLength) private var hairline

    var body: some View {
        NestPanel(.solid, padding: NestSpace.s2) {
            VStack(spacing: NestSpace.s1) {
                Image("mark-tile")
                    .resizable()
                    .frame(width: RailButton.side, height: RailButton.side)
                    .clipShape(RoundedRectangle(cornerRadius: NestRadius.md, style: .continuous))
                    .padding(.bottom, NestSpace.s2)
                    .accessibilityHidden(true)
                ForEach(NestScreen.allCases.filter { !$0.isBelowDivider }, id: \.self, content: button)
                Rectangle()
                    .fill(Color(NestColor.line))
                    .frame(width: RailButton.side - NestSpace.s2, height: hairline)
                    .padding(.vertical, NestSpace.s1)
                ForEach(NestScreen.allCases.filter(\.isBelowDivider), id: \.self, content: button)
            }
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Sections")
    }

    private func button(_ screen: NestScreen) -> some View {
        RailButton(screen: screen, isSelected: selection == screen) { selection = screen }
    }
}
