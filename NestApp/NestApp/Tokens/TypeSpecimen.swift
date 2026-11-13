import NestKit
import SwiftUI

/// Every text style from `tokens.json`, each set in its own sample line.
struct TypeSpecimen: View {
    let styles = NestFont.styles

    var body: some View {
        VStack(alignment: .leading, spacing: NestSpace.s5) {
            ForEach(styles, id: \.name) { style in
                VStack(alignment: .leading, spacing: NestSpace.s1) {
                    Text(style.name)
                        .nestFont(.caption)
                        .foregroundStyle(Color(NestColor.textMuted))
                    Text(style.sample)
                        .nestFont(style)
                        .foregroundStyle(Color(NestColor.textPrimary))
                }
            }
        }
        .padding(NestSpace.s6)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(NestColor.surface0))
    }
}

#Preview {
    TypeSpecimen()
        .task { try? NestFont.registerBundledFonts() }
}
