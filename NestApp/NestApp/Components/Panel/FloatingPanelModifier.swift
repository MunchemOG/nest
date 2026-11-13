import AppKit
import NestKit
import SwiftUI

/// Shows a floating panel over the view while `isPresented` is true; Escape or a click outside closes it.
/// Clicks outside still reach what was clicked, as with a macOS popover.
struct FloatingPanelModifier<Panel: View>: ViewModifier {
    @Binding var isPresented: Bool
    let alignment: Alignment
    let panel: () -> Panel

    @State private var monitor: Any?
    @State private var panelFrame = CGRect.zero

    func body(content: Content) -> some View {
        content
            .overlay(alignment: alignment) {
                if isPresented {
                    NestPanel(.floating, content: panel)
                        .onGeometryChange(for: CGRect.self) { $0.frame(in: .global) } action: { panelFrame = $0 }
                        .transition(.opacity)
                        .onAppear(perform: startListening)
                        .onDisappear(perform: stopListening)
                }
            }
            .animation(.nest(NestMotion.slow), value: isPresented)
    }

    private func startListening() {
        stopListening()
        monitor = NSEvent.addLocalMonitorForEvents(matching: [.keyDown, .leftMouseDown, .rightMouseDown]) { event in
            let dismissal: FloatingPanelDismissal.Event
            if event.type == .keyDown {
                dismissal = .init(event)
            } else {
                let height = event.window?.contentView?.bounds.height ?? 0
                let point = CGPoint(x: event.locationInWindow.x, y: height - event.locationInWindow.y)
                dismissal = MainActor.assumeIsolated { .init(click: point, panel: panelFrame) }
            }
            guard FloatingPanelDismissal.closes(on: dismissal) else { return event }
            MainActor.assumeIsolated { isPresented = false }
            // Escape is used up here; a click still goes on to what was clicked.
            return dismissal == .escape ? nil : event
        }
    }

    private func stopListening() {
        if let monitor { NSEvent.removeMonitor(monitor) }
        monitor = nil
    }
}

extension View {
    /// Shows `panel` floating over this view while `isPresented` is true.
    func nestFloatingPanel(
        isPresented: Binding<Bool>,
        alignment: Alignment = .center,
        @ViewBuilder panel: @escaping () -> some View
    ) -> some View {
        modifier(FloatingPanelModifier(isPresented: isPresented, alignment: alignment, panel: panel))
    }
}
