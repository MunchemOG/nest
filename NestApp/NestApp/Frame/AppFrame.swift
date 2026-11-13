import Foundation
import NestKit
import SwiftUI

/// The main window: the studio background, the rail on the left and the chosen screen on the grid.
struct AppFrame: View {
    @State private var screen = NestScreen.home
    @State private var home = HomeModel()

    /// Each bird's newest action, for the studio's hop.
    private var latestActions: [Bird: NestEvent] {
        Dictionary(uniqueKeysWithValues: Bird.allCases.compactMap { bird in home.flock.state[bird].latestAction.map { (bird, $0) } })
    }

    /// How fast the demo day replays until the birds exist: 60 plays a minute each second.
    private var replaySpeed: Double {
        let speed = UserDefaults.standard.double(forKey: "NestReplaySpeed")
        return speed > 0 ? speed : 60
    }

    var body: some View {
        ZStack(alignment: .leading) {
            Color(NestColor.sceneVoid).ignoresSafeArea()
            if screen == .home {
                StudioView(state: home.studioState, latestActions: latestActions)
                    .ignoresSafeArea()
                    .accessibilityHidden(true)
                    .transition(.opacity)
            }
            Group {
                if screen == .home {
                    HomeScreen(model: home)
                } else if screen == .activity {
                    TimelineScreen(model: home)
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
            guard let events = try? DemoDay.events() else { return }
            let startTime = UserDefaults.standard.string(forKey: "NestReplayStart")
            let (past, future) = DemoReplayStart.split(events, at: startTime)
            past.forEach(home.receive)
            let speed = replaySpeed
            if let start = DemoReplayStart.start(events, at: startTime) {
                let began = Date()
                home.advanceClock(to: start)
                Task {
                    while !Task.isCancelled {
                        try? await Task.sleep(for: .seconds(1))
                        home.advanceClock(to: start.addingTimeInterval(Date().timeIntervalSince(began) * speed))
                    }
                }
            }
            await home.listen(to: ReplaySource(events: future, clock: ContinuousClock(), speed: speed))
        }
        .frame(minWidth: NestSpace.s10 * 10, minHeight: NestSpace.s10 * 6 + NestSpace.s6)
    }
}

#Preview {
    AppFrame()
}
