import NestKit
import SwiftUI

/// A round status dot that can breathe slowly between two colours.
struct StatusDot: View {
    let color: NestColor
    let rest: NestColor
    let breathes: Bool
    var diameter: Double = NestSpace.s2

    var body: some View {
        if breathes {
            dot(color).phaseAnimator([false, true]) { _, faded in
                dot(faded ? rest : color)
            } animation: { _ in
                .nest(NestMotion.breathe / 2, NestMotion.easeInOut)
            }
        } else {
            dot(color)
        }
    }

    private func dot(_ fill: NestColor) -> some View {
        Circle()
            .fill(Color(fill))
            .frame(width: diameter, height: diameter)
    }
}
