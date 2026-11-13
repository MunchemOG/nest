#if DEBUG
import SwiftUI

/// The Debug menu's item that opens the component gallery.
struct GalleryMenuItem: View {
    @Environment(\.openWindow) private var openWindow

    var body: some View {
        Button("Component Gallery") { openWindow(id: ComponentGallery.windowID) }
            .keyboardShortcut("g", modifiers: [.command, .option])
    }
}
#endif
