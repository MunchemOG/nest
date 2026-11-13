import NestKit
import SwiftUI

/// A rounded panel that holds rows, cards or controls.
struct NestPanel<Content: View>: View {
    let kind: NestPanelKind
    let padding: Double
    let content: Content

    @Environment(\.pixelLength) private var hairline

    init(_ kind: NestPanelKind = .solid, padding: Double = NestSpace.s4, @ViewBuilder content: () -> Content) {
        self.kind = kind
        self.padding = padding
        self.content = content()
    }

    var body: some View {
        let shape = RoundedRectangle(cornerRadius: NestRadius.xl, style: .continuous)
        content
            .padding(padding)
            .background {
                ZStack {
                    if kind.usesBackdropBlur {
                        // SwiftUI cannot set a backdrop blur radius; the thinnest system material stands in for blur-glass.
                        shape.fill(.ultraThinMaterial)
                    }
                    shape.fill(Color(kind.fill))
                }
            }
            .overlay { shape.strokeBorder(Color(NestColor.line), lineWidth: hairline) }
            .nestShadow(kind.shadow, in: shape)
    }
}
