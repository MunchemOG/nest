import Foundation
import NestKit
import SwiftUI

/// The main window: the studio background, the rail on the left and the chosen screen on the grid.
struct AppFrame: View {
    @State private var screen = NestScreen.home
    @State private var home = HomeModel()

    /// How fast the demo day replays until the birds exist: 60 plays a minute each second.
    private var replaySpeed: Double {
        let speed = UserDefaults.standard.double(forKey: "NestReplaySpeed")
        return speed > 0 ? speed : 60
    }

    var body: some View {
        ZStack(alignment: .leading) {
            Color(NestColor.sceneVoid).ignoresSafeArea()
            Group {
                if screen == .home {
                    HomeScreen(model: home)
                } else {
                    ScreenPlaceholder(screen: screen)
                }
            }
                .id(screen)
                .transition(.opacity)
                .padding(.leading, NestSpace.s9 + NestSpace.s4)
                .padding([.top, .trailing, .bottom], NestSpace.s6)
            Rail(selection: $screen)
                .padding(.leading, NestSpace.s5)
        }
        .animation(.nest(NestMotion.base), value: screen)
        .focusedSceneValue(\.nestScreen, $screen)
        .task {
            guard let replay = try? ReplaySource.demoDay(clock: ContinuousClock(), speed: replaySpeed) else { return }
            await home.listen(to: replay)
        }
        .frame(minWidth: NestSpace.s10 * 6, minHeight: NestSpace.s10 * 4)
    }
}

#Preview {
    AppFrame()
}
