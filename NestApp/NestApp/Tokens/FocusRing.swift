import NestKit
import SwiftUI

/// Draws `shadow-focus` around a shape: rings that grow past its edge, and a soft glow, never under it.
struct FocusRing<RingShape: InsettableShape>: ViewModifier {
    let shape: RingShape
    let isShown: Bool

    @Environment(\.nestAccent) private var accent

    private var layers: [NestShadow.Layer] { Self.layers(accent: accent) }

    /// `shadow-focus` with its clay rings and glow in the accent instead.
    static func layers(accent: NestAccent) -> [NestShadow.Layer] {
        NestShadow.focus.layers.map { layer in
            let c = layer.color, clay = NestColor.clay
            guard c.red == clay.red, c.green == clay.green, c.blue == clay.blue else { return layer }
            let a = accent.fill
            return NestShadow.Layer(inset: layer.inset, x: layer.x, y: layer.y, blur: layer.blur, spread: layer.spread,
                                    color: NestColor(red: a.red, green: a.green, blue: a.blue, alpha: c.alpha))
        }
    }

    /// The ring's colours in an accent.
    static func colours(accent: NestAccent) -> [NestColor] { layers(accent: accent).map(\.color) }
    private var reach: Double { layers.map { $0.spread + $0.blur }.max() ?? 0 }

    func body(content: Content) -> some View {
        content.background {
            if isShown {
                ZStack {
                    ForEach(Array(layers.enumerated().reversed()), id: \.offset) { _, layer in
                        ring(layer)
                    }
                }
                .mask {
                    Rectangle()
                        .padding(-reach)
                        .overlay { shape.blendMode(.destinationOut) }
                        .compositingGroup()
                }
            }
        }
    }

    @ViewBuilder private func ring(_ layer: NestShadow.Layer) -> some View {
        if layer.blur == 0 {
            shape.inset(by: -layer.spread / 2).stroke(Color(layer.color), lineWidth: layer.spread)
        } else {
            // A CSS blur radius is twice the Gaussian's deviation.
            shape.inset(by: -layer.spread).fill(Color(layer.color)).blur(radius: layer.blur / 2)
        }
    }
}

extension View {
    /// Shows the keyboard focus ring around `shape` while `isShown` is true.
    func nestFocusRing(_ isShown: Bool, in shape: some InsettableShape) -> some View {
        modifier(FocusRing(shape: shape, isShown: isShown))
    }
}
