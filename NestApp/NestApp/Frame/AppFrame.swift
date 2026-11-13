import NestKit
import SwiftUI

/// The main window: the studio background, the rail on the left and the chosen screen on the grid.
struct AppFrame: View {
    @State private var screen = NestScreen.home

    var body: some View {
        ZStack(alignment: .leading) {
            Color(NestColor.sceneVoid).ignoresSafeArea()
            ScreenPlaceholder(screen: screen)
                .id(screen)
                .transition(.opacity)
                .padding(.leading, NestSpace.s9 + NestSpace.s4)
                .padding([.top, .trailing, .bottom], NestSpace.s6)
            Rail(selection: $screen)
                .padding(.leading, NestSpace.s5)
        }
        .animation(.nest(NestMotion.base), value: screen)
        .focusedSceneValue(\.nestScreen, $screen)
        .frame(minWidth: NestSpace.s10 * 6, minHeight: NestSpace.s10 * 4)
    }
}

#Preview {
    AppFrame()
}
