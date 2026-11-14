import SwiftUI

/// The Nest's menu bar menu: the "I'm here" switch that tells Swift to stand down.
struct PresenceMenu: View {
    @Bindable var presence: PresenceSwitch

    var body: some View {
        Toggle("I'm here", isOn: $presence.isHere)
    }
}
