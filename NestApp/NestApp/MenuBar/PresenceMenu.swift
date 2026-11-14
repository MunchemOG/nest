import AppKit
import SwiftUI

/// The Nest's menu bar menu: the "I'm here" switch that tells Swift to stand down, and the small Swift.
struct PresenceMenu: View {
    @Bindable var presence: PresenceSwitch

    @Environment(\.openWindow) private var openWindow

    var body: some View {
        Toggle("I'm here", isOn: $presence.isHere)
        Divider()
        Button("Open Swift") {
            openWindow(id: SwiftMiniWindow.id)
            NSApplication.shared.activate()
        }
        .keyboardShortcut("s", modifiers: [.command, .shift])
    }
}
