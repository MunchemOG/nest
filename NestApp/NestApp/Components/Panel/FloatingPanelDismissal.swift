import AppKit

/// Decides which events close a floating panel.
enum FloatingPanelDismissal {
    /// Something that happened while a floating panel was open.
    enum Event: Hashable, Sendable {
        case escape
        case otherKey
        case clickInside
        case clickOutside

        /// The key event's meaning: Escape, or any other key.
        init(_ key: NSEvent) {
            self = key.keyCode == escapeKeyCode ? .escape : .otherKey
        }

        /// A click at `point`, inside or outside the panel's `frame` (both in the same coordinates).
        init(click point: CGPoint, panel frame: CGRect) {
            self = frame.contains(point) ? .clickInside : .clickOutside
        }
    }

    /// The hardware key code of the Escape key.
    static let escapeKeyCode: UInt16 = 53

    /// Whether the event closes the panel.
    static func closes(on event: Event) -> Bool {
        event == .escape || event == .clickOutside
    }
}
