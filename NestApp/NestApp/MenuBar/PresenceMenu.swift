import AppKit
import SwiftUI

/// The Nest's menu bar menu: what Swift makes of you, a switch to hold it, and the small Swift.
/// Without the automatic watcher (as in tests), the plain "I'm here" switch stands in.
struct PresenceMenu: View {
    @Bindable var presence: PresenceSwitch
    var auto: AutoPresence?

    @Environment(\.openWindow) private var openWindow

    var body: some View {
        if let auto {
            Text(auto.status)
            Toggle("Hold Swift", isOn: Binding(get: { auto.hold }, set: { auto.hold = $0 }))
        } else {
            Toggle("I'm here", isOn: $presence.isHere)
        }
        Divider()
        Button("Open Swift") {
            openWindow(id: SwiftMiniWindow.id)
            NSApplication.shared.activate()
        }
        .keyboardShortcut("s", modifiers: [.command, .shift])
    }
}
