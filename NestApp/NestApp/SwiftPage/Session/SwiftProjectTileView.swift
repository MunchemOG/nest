import NestKit
import SwiftUI

/// A project's tile: its initial in dark ink on its accent colour, lit from the top like the birds' tiles.
struct SwiftProjectTileView: View {
    let project: SwiftProject
    let size: Double

    var body: some View {
        let shape = RoundedRectangle(cornerRadius: size >= NestSpace.s7 ? NestRadius.lg : NestRadius.md, style: .continuous)
        Text(project.initial)
            .font(.nest(.displayM))
            .minimumScaleFactor(0.1)
            .foregroundStyle(Color(NestColor.glyphInk))
            .padding(size / 4)
            .frame(width: size, height: size)
            .background {
                shape.fill(LinearGradient(colors: [Color(project.tile.light), Color(project.tile.color)],
                                          startPoint: .topLeading, endPoint: .bottomTrailing))
            }
            .nestShadow(.icon, in: shape)
            .accessibilityHidden(true)
    }
}
