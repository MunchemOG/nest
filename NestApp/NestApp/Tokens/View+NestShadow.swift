import NestKit
import SwiftUI

/// Draws a shadow token around a shape: outer layers fall outside it, inset layers sit inside its edge.
struct NestShadowModifier<ShadowShape: Shape>: ViewModifier {
    let shadow: NestShadow
    let shape: ShadowShape

    func body(content: Content) -> some View {
        content
            .background {
                ZStack {
                    ForEach(Array(outer.enumerated().reversed()), id: \.offset) { _, layer in
                        shape
                            .fill(Color(layer.color))
                            .padding(-layer.spread)
                            .offset(x: layer.x, y: layer.y)
                            // A CSS blur radius is twice the Gaussian's deviation.
                            .blur(radius: layer.blur / 2)
                    }
                }
                .mask { outside }
            }
            .overlay {
                ZStack {
                    ForEach(Array(inset.enumerated().reversed()), id: \.offset) { _, layer in
                        shape
                            .fill(Color(layer.color))
                            .mask {
                                Rectangle()
                                    .overlay { shape.offset(x: layer.x, y: layer.y).blendMode(.destinationOut) }
                                    .compositingGroup()
                            }
                            .blur(radius: layer.blur / 2)
                    }
                }
                .clipShape(shape)
                .allowsHitTesting(false)
            }
    }

    private var outer: [NestShadow.Layer] { shadow.layers.filter { !$0.inset } }
    private var inset: [NestShadow.Layer] { shadow.layers.filter(\.inset) }

    private var reach: Double {
        outer.map { max(abs($0.x), abs($0.y)) + $0.blur + max($0.spread, 0) }.max() ?? 0
    }

    private var outside: some View {
        Rectangle()
            .padding(-reach)
            .overlay { shape.blendMode(.destinationOut) }
            .compositingGroup()
    }
}

extension View {
    /// Draws a shadow token around `shape`, never under it.
    func nestShadow(_ shadow: NestShadow, in shape: some Shape) -> some View {
        modifier(NestShadowModifier(shadow: shadow, shape: shape))
    }
}
