import NestKit
import SwiftUI

/// The small Swift: a floating window with the same live Claude Code session as Swift's close-up.
/// The menu bar opens it now; once the birds fly over the desktop, clicking Swift will too.
struct SwiftMiniWindow: View {
    /// The window's id, for opening it.
    static let id = "swift-mini"

    let home: HomeModel

    @State private var launcher = false
    @Environment(\.dismissWindow) private var dismissWindow

    var body: some View {
        Group {
            if let sessions = home.swiftSessions {
                SwiftSessionPanel(sessions: sessions, compact: true, switchProject: { launcher = true },
                                  close: { dismissWindow(id: Self.id) })
                    .sheet(isPresented: $launcher) {
                        SwiftLauncher(sessions: sessions) { launcher = false }
                            .frame(minWidth: HomeLayout.session, minHeight: NestSpace.s10 * 4)
                    }
            } else {
                Text("Swift couldn't open its folder.")
                    .nestFont(.bodyS)
                    .foregroundStyle(Color(NestColor.textSecondary))
            }
        }
        .padding(NestSpace.s2)
        .frame(minWidth: NestSpace.s10 * 3 + NestSpace.s8, minHeight: NestSpace.s10 * 3)
        .background(Color(NestColor.sceneVoid))
        .environment(\.colorScheme, .dark)
        .onAppear { home.prepareSwift() }
    }
}
