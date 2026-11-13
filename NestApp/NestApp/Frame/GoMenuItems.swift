import SwiftUI

/// The Go menu: one item per screen, with ⌘1 to ⌘4.
struct GoMenuItems: View {
    @FocusedBinding(\.nestScreen) private var screen

    var body: some View {
        ForEach(NestScreen.allCases, id: \.self) { item in
            Button(item.title) { screen = item }
                .keyboardShortcut(KeyEquivalent(item.shortcut), modifiers: .command)
                .disabled(screen == nil)
        }
    }
}
